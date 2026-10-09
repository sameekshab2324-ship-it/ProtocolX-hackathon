create table if not exists public.conversation_records (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) <= 200),
  transcript text not null check (octet_length(transcript) <= 5242880),
  identity text not null default '',
  summary text not null default '',
  message_count integer not null default 0 check (message_count >= 0),
  actions jsonb not null default '[]'::jsonb check (jsonb_typeof(actions) = 'array'),
  decisions jsonb not null default '[]'::jsonb check (jsonb_typeof(decisions) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.conversation_records enable row level security;

create index if not exists conversation_records_user_updated_idx
  on public.conversation_records (user_id, updated_at desc);

revoke all on table public.conversation_records from anon;
grant select, insert, update, delete on table public.conversation_records to authenticated;

drop policy if exists "Users can read their own conversations" on public.conversation_records;
create policy "Users can read their own conversations"
  on public.conversation_records for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own conversations" on public.conversation_records;
create policy "Users can insert their own conversations"
  on public.conversation_records for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own conversations" on public.conversation_records;
create policy "Users can update their own conversations"
  on public.conversation_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own conversations" on public.conversation_records;
create policy "Users can delete their own conversations"
  on public.conversation_records for delete to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.set_conversation_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists conversation_records_set_updated_at on public.conversation_records;
create trigger conversation_records_set_updated_at
  before update on public.conversation_records
  for each row execute function public.set_conversation_updated_at();
