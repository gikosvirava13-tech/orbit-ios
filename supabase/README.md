setup

what you do, once. the app builds and runs without any of this — it falls back
to an in-memory backend, which is also what CI screenshots — but nothing is
shared between devices until it is done.

1. create the project

   supabase.com -> new project. pick a region close to you; every round trip
   pays for it. note the database password somewhere safe, you cannot read it
   back later.

2. run the migrations

   sql editor -> new query. paste migrations/0001_init.sql, run. then
   migrations/0002_views.sql, run. order matters, 0002 builds on 0001.

   or, with the cli:

       supabase link --project-ref <ref>
       supabase db push

3. turn on email auth

   authentication -> providers -> email. leave "confirm email" on for a real
   product; turn it off while testing on your own devices so you are not
   waiting on inboxes.

   authentication -> url configuration -> add totem:// as a redirect url.

4. point the app at it

   copy Config/Secrets.local.xcconfig.example to
   Config/Secrets.local.xcconfig, fill in:

       SUPABASE_PROJECT_REF   the subdomain of your project url
       SUPABASE_ANON_KEY      settings -> api -> anon public

   that file is gitignored. the anon key is designed to be public — every
   table is behind row level security — but there is no reason for it to be in
   the repo.

what the schema does

   profiles              one row per account, created by a trigger on signup
   friendships           one row per pair, stored directed, read undirected
   conversations         carries last_seq and a denormalised last message
   conversation_members  membership plus per-person read state, mute, pin
   messages              body plus a per-conversation seq and a client_id

   chat_list             the whole chat list screen, one query
   friends               accepted friendships, flattened to "the other person"
   search_people(q)      profiles plus your relationship to each

three things worth knowing before you change any of it

   seq. every message gets a per-conversation sequence number, allocated under
   a row lock on the conversation. it is the ordering key, the pagination
   cursor, and the basis of unread counts — unread is last_seq minus
   last_read_seq, a subtraction rather than a count. timestamps cannot do this
   job: two phones disagree about the time.

   client_id. the client generates it before the first send attempt and reuses
   it on every retry. there is a unique index on (conversation_id, client_id),
   so a send that times out and gets retried lands exactly once.

   security_invoker. every view sets it. without it a postgres view runs as
   its owner and quietly ignores row level security, which is the most common
   way a supabase project ends up serving every row in a table to anyone who
   asks.

limits

   free tier is 200 concurrent realtime connections, pro is 500 with add-ons
   above that. a thousand people connected at once needs pro plus an add-on.
   database size and egress are not the constraint at this scale; connection
   count is.
