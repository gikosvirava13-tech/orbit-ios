-- Read models.
--
-- The app talks to these rather than assembling screens out of joins on the
-- client. One round trip per screen is the whole point: at a thousand users
-- the cost that matters is the number of requests, not the size of them.
--
-- Every view is declared `security_invoker`. Without it a Postgres view runs
-- as its owner and quietly bypasses row level security — the single most
-- common way a Supabase project leaks every row in a table.

-- ---------------------------------------------------------------------------
-- Chat list
-- ---------------------------------------------------------------------------

create or replace view public.chat_list as
select
    c.id,
    c.kind,
    c.created_at,
    c.last_seq,
    c.last_message_at,
    c.last_message_preview,
    c.last_message_sender,

    m.last_read_seq,
    m.is_muted,
    m.is_pinned,

    -- Subtraction, not a count. This is why `seq` exists.
    greatest(c.last_seq - m.last_read_seq, 0) as unread_count,

    coalesce(c.title, peer.display_name) as title,

    peer.id          as peer_id,
    peer.username    as peer_username,
    peer.avatar_path as peer_avatar_path,
    peer.last_seen   as peer_last_seen,

    (
        select count(*)
          from public.conversation_members cm
         where cm.conversation_id = c.id
    ) as member_count
from public.conversations c
join public.conversation_members m
  on m.conversation_id = c.id
 and m.user_id = auth.uid()
left join lateral (
    select p.id, p.display_name, p.username, p.avatar_path, p.last_seen
      from public.conversation_members om
      join public.profiles p on p.id = om.user_id
     where om.conversation_id = c.id
       and om.user_id <> auth.uid()
     limit 1
) peer on c.kind = 'direct';

alter view public.chat_list set (security_invoker = on);

-- ---------------------------------------------------------------------------
-- Friends
-- ---------------------------------------------------------------------------

-- Friendship is stored directed and read undirected: one row per person you
-- are actually friends with, regardless of who asked.
create or replace view public.friends as
select
    case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end as friend_id,
    p.username,
    p.display_name,
    p.bio,
    p.avatar_path,
    p.last_seen,
    f.created_at as friends_since
from public.friendships f
join public.profiles p
  on p.id = case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end
where f.status = 'accepted'
  and (f.requester_id = auth.uid() or f.addressee_id = auth.uid());

alter view public.friends set (security_invoker = on);

-- Requests waiting on you, with the sender's profile attached so the screen
-- needs no second lookup.
create or replace view public.friend_requests_incoming as
select
    f.id as request_id,
    f.created_at,
    p.id as sender_id,
    p.username,
    p.display_name,
    p.bio,
    p.avatar_path
from public.friendships f
join public.profiles p on p.id = f.requester_id
where f.status = 'pending'
  and f.addressee_id = auth.uid();

alter view public.friend_requests_incoming set (security_invoker = on);

create or replace view public.friend_requests_outgoing as
select
    f.id as request_id,
    f.created_at,
    p.id as recipient_id,
    p.username,
    p.display_name,
    p.avatar_path
from public.friendships f
join public.profiles p on p.id = f.addressee_id
where f.status = 'pending'
  and f.requester_id = auth.uid();

alter view public.friend_requests_outgoing set (security_invoker = on);

-- ---------------------------------------------------------------------------
-- People search
-- ---------------------------------------------------------------------------

-- Returns the relationship alongside the profile, so the button on each row
-- ("Add", "Pending", "Message") is decided by the server rather than by the
-- client cross-referencing two lists.
create or replace function public.search_people(query text, max_results int default 20)
returns table (
    id            uuid,
    username      citext,
    display_name  text,
    bio           text,
    avatar_path   text,
    relationship  text
)
language sql
stable
security invoker
set search_path = public
as $$
    select
        p.id,
        p.username,
        p.display_name,
        p.bio,
        p.avatar_path,
        coalesce(
            (
                select case
                    when f.status = 'accepted' then 'friends'
                    when f.status = 'blocked'  then 'blocked'
                    when f.requester_id = auth.uid() then 'requested'
                    else 'incoming'
                end
                  from public.friendships f
                 where least(f.requester_id, f.addressee_id) = least(p.id, auth.uid())
                   and greatest(f.requester_id, f.addressee_id) = greatest(p.id, auth.uid())
            ),
            'none'
        ) as relationship
    from public.profiles p
    where p.id <> auth.uid()
      and (
            p.username ilike query || '%'
         or p.display_name ilike '%' || query || '%'
      )
    order by
        -- Exact username first, then prefix matches, then the rest.
        (p.username = query::citext) desc,
        (p.username ilike query || '%') desc,
        p.username
    limit least(max_results, 50);
$$;

-- ---------------------------------------------------------------------------
-- History
-- ---------------------------------------------------------------------------

-- Cursor pagination on `seq`. Passing `before_seq = null` gets the newest
-- page; passing the lowest `seq` you hold gets the one before it. Never
-- OFFSET — it re-scans everything it skips, and it shifts under inserts.
create or replace function public.message_page(
    conversation uuid,
    before_seq   bigint default null,
    page_size    int default 40
)
returns table (
    id                uuid,
    conversation_id   uuid,
    sender_id         uuid,
    sender_username   citext,
    sender_name       text,
    sender_avatar     text,
    seq               bigint,
    body              text,
    client_id         uuid,
    created_at        timestamptz,
    edited_at         timestamptz,
    deleted_at        timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
    select
        m.id,
        m.conversation_id,
        m.sender_id,
        p.username,
        p.display_name,
        p.avatar_path,
        m.seq,
        case when m.deleted_at is null then m.body else '' end,
        m.client_id,
        m.created_at,
        m.edited_at,
        m.deleted_at
    from public.messages m
    join public.profiles p on p.id = m.sender_id
    where m.conversation_id = conversation
      and (before_seq is null or m.seq < before_seq)
    order by m.seq desc
    limit least(page_size, 100);
$$;

-- ---------------------------------------------------------------------------
-- Presence
-- ---------------------------------------------------------------------------

-- Called on foreground and on a slow timer. Live presence rides on Realtime's
-- own presence channel; this is only the "last seen" fallback for people who
-- are not currently connected.
create or replace function public.touch_last_seen()
returns void
language sql
security definer
set search_path = public
as $$
    update public.profiles
       set last_seen = now()
     where id = auth.uid();
$$;
