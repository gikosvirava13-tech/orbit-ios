-- Totem: initial schema.
--
-- Run this in the Supabase SQL editor, or with `supabase db push`.
--
-- Design notes that matter at scale:
--
--   * Every message carries a per-conversation `seq`, allocated under a row
--     lock on the conversation. That single counter gives stable ordering,
--     cursor pagination, and unread counts without ever counting rows.
--
--   * Conversations carry a denormalised preview of their last message, so
--     the chat list is one query rather than one query plus N.
--
--   * `(conversation_id, client_id)` is unique, so a retried send can never
--     duplicate. The client generates `client_id` before the first attempt.
--
--   * Membership checks go through a SECURITY DEFINER function. A policy on
--     conversation_members that queries conversation_members recurses
--     infinitely; this is the standard way out.

create extension if not exists "citext";
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------

create table if not exists public.profiles (
    id           uuid primary key references auth.users (id) on delete cascade,
    username     citext not null unique,
    display_name text   not null,
    bio          text   not null default '',
    avatar_path  text,
    last_seen    timestamptz not null default now(),
    created_at   timestamptz not null default now(),

    constraint username_format check (username ~ '^[a-z0-9_]{3,24}$')
);

comment on column public.profiles.avatar_path is
    'Path inside the "avatars" storage bucket, not a URL. URLs expire; paths do not.';

-- Username lookup is the search path for adding friends, so it needs to be
-- prefix-searchable as well as unique.
create index if not exists profiles_username_prefix
    on public.profiles (username text_pattern_ops);

-- ---------------------------------------------------------------------------
-- Friendships
-- ---------------------------------------------------------------------------

create type public.friend_status as enum ('pending', 'accepted', 'blocked');

create table if not exists public.friendships (
    id           uuid primary key default gen_random_uuid(),
    requester_id uuid not null references public.profiles (id) on delete cascade,
    addressee_id uuid not null references public.profiles (id) on delete cascade,
    status       public.friend_status not null default 'pending',
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now(),

    constraint no_self_friendship check (requester_id <> addressee_id)
);

-- One row per pair, whichever direction the request came from. The expression
-- index is what actually enforces that.
create unique index if not exists friendships_pair
    on public.friendships (
        least(requester_id, addressee_id),
        greatest(requester_id, addressee_id)
    );

create index if not exists friendships_addressee
    on public.friendships (addressee_id, status);

create index if not exists friendships_requester
    on public.friendships (requester_id, status);

-- ---------------------------------------------------------------------------
-- Conversations
-- ---------------------------------------------------------------------------

create type public.conversation_kind as enum ('direct', 'group', 'channel');

create table if not exists public.conversations (
    id         uuid primary key default gen_random_uuid(),
    kind       public.conversation_kind not null default 'direct',
    title      text,
    created_by uuid references public.profiles (id) on delete set null,
    created_at timestamptz not null default now(),

    -- Monotonic per conversation. Also the high-water mark for unread maths.
    last_seq   bigint not null default 0,

    -- Denormalised so the chat list never joins to messages.
    last_message_at      timestamptz,
    last_message_preview text,
    last_message_sender  uuid references public.profiles (id) on delete set null,

    -- Deterministic key for a two-person chat, so opening the same person
    -- twice cannot create a second conversation. Null for groups.
    direct_key text unique,

    constraint direct_needs_key check (kind <> 'direct' or direct_key is not null)
);

-- The chat list is ordered by this, filtered to the caller's memberships.
create index if not exists conversations_recent
    on public.conversations (last_message_at desc nulls last);

create table if not exists public.conversation_members (
    conversation_id uuid not null references public.conversations (id) on delete cascade,
    user_id         uuid not null references public.profiles (id) on delete cascade,
    role            text not null default 'member',
    joined_at       timestamptz not null default now(),

    -- Unread count is `conversations.last_seq - last_read_seq`. No row counting.
    last_read_seq   bigint not null default 0,
    is_muted        boolean not null default false,
    is_pinned       boolean not null default false,

    primary key (conversation_id, user_id)
);

-- "Every conversation I am in", the first query the app makes after login.
create index if not exists conversation_members_by_user
    on public.conversation_members (user_id);

-- ---------------------------------------------------------------------------
-- Messages
-- ---------------------------------------------------------------------------

create table if not exists public.messages (
    id              uuid primary key default gen_random_uuid(),
    conversation_id uuid not null references public.conversations (id) on delete cascade,
    sender_id       uuid not null references public.profiles (id) on delete cascade,

    -- Assigned by trigger. Never trust a client-supplied sequence number.
    seq             bigint not null default 0,

    body            text not null,
    client_id       uuid not null,
    created_at      timestamptz not null default now(),
    edited_at       timestamptz,
    deleted_at      timestamptz,

    constraint body_not_blank check (deleted_at is not null or length(btrim(body)) > 0),
    constraint body_length    check (length(body) <= 4000)
);

-- The pagination index. Descending because history is read newest-first.
create unique index if not exists messages_conversation_seq
    on public.messages (conversation_id, seq desc);

-- Idempotency: a retried send collides here instead of duplicating.
create unique index if not exists messages_client_id
    on public.messages (conversation_id, client_id);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- SECURITY DEFINER so it can read conversation_members without tripping the
-- policy that is itself defined in terms of this function.
create or replace function public.is_member(conversation uuid, member uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
    select exists (
        select 1
          from public.conversation_members m
         where m.conversation_id = conversation
           and m.user_id = member
    );
$$;

-- Creates the profile row that every other table points at. Without this a
-- user could authenticate and then have nowhere to exist.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, username, display_name)
    values (
        new.id,
        coalesce(
            nullif(new.raw_user_meta_data ->> 'username', ''),
            'user_' || substr(replace(new.id::text, '-', ''), 1, 12)
        ),
        coalesce(
            nullif(new.raw_user_meta_data ->> 'display_name', ''),
            'New User'
        )
    );

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- Allocates the next sequence number and updates the conversation preview in
-- the same statement. The UPDATE takes a row lock, which serialises writes
-- within one conversation — exactly the ordering guarantee we want — while
-- leaving separate conversations free to run in parallel.
create or replace function public.assign_message_seq()
returns trigger
language plpgsql
as $$
declare
    next_seq bigint;
begin
    update public.conversations
       set last_seq             = last_seq + 1,
           last_message_at      = now(),
           last_message_preview = left(new.body, 140),
           last_message_sender  = new.sender_id
     where id = new.conversation_id
    returning last_seq into next_seq;

    if next_seq is null then
        raise exception 'conversation % does not exist', new.conversation_id;
    end if;

    new.seq := next_seq;

    return new;
end;
$$;

drop trigger if exists messages_assign_seq on public.messages;

create trigger messages_assign_seq
    before insert on public.messages
    for each row execute function public.assign_message_seq();

-- Opening a chat with someone is idempotent: same pair, same conversation,
-- however many times either side taps it.
create or replace function public.open_direct_conversation(other_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    me           uuid := auth.uid();
    pair_key     text;
    existing_id  uuid;
    new_id       uuid;
begin
    if me is null then
        raise exception 'not authenticated';
    end if;

    if me = other_user then
        raise exception 'cannot open a conversation with yourself';
    end if;

    pair_key := least(me, other_user)::text || ':' || greatest(me, other_user)::text;

    select id into existing_id
      from public.conversations
     where direct_key = pair_key;

    if existing_id is not null then
        return existing_id;
    end if;

    insert into public.conversations (kind, created_by, direct_key)
    values ('direct', me, pair_key)
    returning id into new_id;

    insert into public.conversation_members (conversation_id, user_id)
    values (new_id, me), (new_id, other_user);

    return new_id;

exception
    -- Both sides tapping at once: one insert wins, the other reads the winner.
    when unique_violation then
        select id into existing_id
          from public.conversations
         where direct_key = pair_key;

        return existing_id;
end;
$$;

-- Read state moves forward only. Two devices racing cannot un-read a chat.
create or replace function public.mark_read(conversation uuid, up_to_seq bigint)
returns void
language sql
security definer
set search_path = public
as $$
    update public.conversation_members
       set last_read_seq = greatest(last_read_seq, up_to_seq)
     where conversation_id = conversation
       and user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.profiles             enable row level security;
alter table public.friendships          enable row level security;
alter table public.conversations        enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages             enable row level security;

-- Profiles: visible to any signed-in user, since you have to be able to find
-- someone by username before you can befriend them. Writable only by owner.
create policy profiles_read on public.profiles
    for select to authenticated using (true);

create policy profiles_update_own on public.profiles
    for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Friendships: only the two people involved can see or change a row.
create policy friendships_read on public.friendships
    for select to authenticated
    using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy friendships_request on public.friendships
    for insert to authenticated
    with check (requester_id = auth.uid());

create policy friendships_respond on public.friendships
    for update to authenticated
    using (requester_id = auth.uid() or addressee_id = auth.uid())
    with check (requester_id = auth.uid() or addressee_id = auth.uid());

create policy friendships_delete on public.friendships
    for delete to authenticated
    using (requester_id = auth.uid() or addressee_id = auth.uid());

-- Conversations: members only.
create policy conversations_read on public.conversations
    for select to authenticated
    using (public.is_member(id, auth.uid()));

create policy conversations_create on public.conversations
    for insert to authenticated
    with check (created_by = auth.uid());

create policy conversations_update on public.conversations
    for update to authenticated
    using (public.is_member(id, auth.uid()));

-- Membership rows: you can see who else is in a conversation you belong to,
-- and change only your own row (mute, pin, read state).
create policy members_read on public.conversation_members
    for select to authenticated
    using (public.is_member(conversation_id, auth.uid()));

create policy members_join on public.conversation_members
    for insert to authenticated
    with check (user_id = auth.uid() or public.is_member(conversation_id, auth.uid()));

create policy members_update_own on public.conversation_members
    for update to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy members_leave on public.conversation_members
    for delete to authenticated
    using (user_id = auth.uid());

-- Messages: read if you are in the room, write only as yourself, edit only
-- your own. Nothing is ever hard deleted — deleted_at is set instead, so the
-- sequence stays contiguous and other clients can reconcile.
create policy messages_read on public.messages
    for select to authenticated
    using (public.is_member(conversation_id, auth.uid()));

create policy messages_send on public.messages
    for insert to authenticated
    with check (
        sender_id = auth.uid()
        and public.is_member(conversation_id, auth.uid())
    );

create policy messages_edit_own on public.messages
    for update to authenticated
    using (sender_id = auth.uid()) with check (sender_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

-- Realtime honours the policies above, so a client only ever receives rows it
-- could have selected. Conversations are published too, because the chat list
-- reorders on last_message_at without any message being visible yet.
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.conversation_members;
alter publication supabase_realtime add table public.friendships;

-- ---------------------------------------------------------------------------
-- Avatar storage
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy avatars_read on storage.objects
    for select to public using (bucket_id = 'avatars');

-- Each user owns the folder named after their id: avatars/<uid>/<file>.
create policy avatars_write on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy avatars_update on storage.objects
    for update to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy avatars_delete on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
