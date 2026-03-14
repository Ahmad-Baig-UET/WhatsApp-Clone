-- ============================================================
-- VI-hatsApp v2 — Full Supabase Setup
-- Run this in your Supabase SQL Editor (fresh project)
-- ============================================================

-- 1. USERS TABLE
create table public.users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  display_name text not null,
  avatar_color text not null default '#00e5ff',
  pin_hash text not null,
  is_og boolean default false,       -- true = can access group chat
  created_at timestamptz default now()
);

-- 2. DM CHATS TABLE (one row per DM conversation)
create table public.dm_chats (
  id uuid primary key default gen_random_uuid(),
  user_a uuid references public.users(id) on delete cascade not null,
  user_b uuid references public.users(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_a, user_b)
);

-- 3. MESSAGES TABLE (used for both group and DMs)
-- chat_id = 'group' for group chat, or dm_chats.id for DMs
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade not null,
  chat_id text not null,
  content text,
  image_url text,
  reply_to uuid references public.messages(id) on delete set null,
  deleted boolean default false,
  created_at timestamptz default now(),
  constraint content_or_image check (content is not null or image_url is not null)
);

-- 4. REACTIONS TABLE
create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid references public.messages(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  emoji text not null,
  created_at timestamptz default now(),
  unique(message_id, user_id, emoji)
);

-- 5. READ RECEIPTS TABLE
create table public.read_receipts (
  id uuid primary key default gen_random_uuid(),
  message_id uuid references public.messages(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  read_at timestamptz default now(),
  unique(message_id, user_id)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.users enable row level security;
alter table public.dm_chats enable row level security;
alter table public.messages enable row level security;
alter table public.reactions enable row level security;
alter table public.read_receipts enable row level security;

-- Users: public read, anyone can insert (sign up), no delete
create policy "Users readable by all" on public.users for select using (true);
create policy "Anyone can create user" on public.users for insert with check (true);

-- DM chats: readable & insertable by all
create policy "DM chats readable" on public.dm_chats for select using (true);
create policy "Anyone can create DM" on public.dm_chats for insert with check (true);

-- Messages: readable & insertable & updatable by all
create policy "Messages readable" on public.messages for select using (true);
create policy "Anyone can send message" on public.messages for insert with check (true);
create policy "Anyone can update message" on public.messages for update using (true);

-- Reactions
create policy "Reactions readable" on public.reactions for select using (true);
create policy "Anyone can react" on public.reactions for insert with check (true);
create policy "Anyone can remove reaction" on public.reactions for delete using (true);

-- Read receipts
create policy "Receipts readable" on public.read_receipts for select using (true);
create policy "Anyone can mark read" on public.read_receipts for insert with check (true);

-- ============================================================
-- INDEXES
-- ============================================================
create index messages_chat_id_idx on public.messages(chat_id, created_at asc);
create index reactions_message_id_idx on public.reactions(message_id);
create index read_receipts_message_id_idx on public.read_receipts(message_id);
create index dm_chats_users_idx on public.dm_chats(user_a, user_b);

-- ============================================================
-- INSERT THE 6 OG USERS
-- Run the app locally first, go to /generate-pins to get hashes
-- Then replace the REPLACE_WITH_HASH values below
-- ============================================================
insert into public.users (username, display_name, avatar_color, pin_hash, is_og) values
  ('haseeb', 'Haseeb', '#FF6B6B', 'REPLACE_WITH_HASEEB_HASH', true),
  ('ahmad',  'Ahmad',  '#4ECDC4', 'REPLACE_WITH_AHMAD_HASH',  true),
  ('zaryan', 'Zaryan', '#45B7D1', 'REPLACE_WITH_ZARYAN_HASH', true),
  ('taha',   'Taha',   '#96CEB4', 'REPLACE_WITH_TAHA_HASH',   true),
  ('qasim',  'Qasim',  '#FFD93D', 'REPLACE_WITH_QASIM_HASH',  true),
  ('muneeb', 'Muneeb', '#C77DFF', 'REPLACE_WITH_MUNEEB_HASH', true);

-- ============================================================
-- STORAGE BUCKETS
-- Create these manually in Supabase → Storage:
--   1. "chat-images"   → Public: ON
--   2. "voice-messages" → Public: ON
-- ============================================================

-- ============================================================
-- REALTIME
-- Go to Database → Publications → supabase_realtime
-- Enable: messages, reactions, read_receipts
-- ============================================================
