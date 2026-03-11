-- Epic Gold Shop - esquema inicial para Supabase/PostgreSQL

create extension if not exists "pgcrypto";

create table if not exists public.settings (
  id uuid primary key default gen_random_uuid(),
  discord text,
  whatsapp text,
  tiktok text,
  email text,
  site text,
  updated_at timestamptz not null default now()
);

create table if not exists public.gold_categories (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text,
  description text,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_servers (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.gold (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  amount integer not null default 0,
  price numeric(12,2) not null default 0,
  delivery text,
  stock text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  type text default 'account',
  category text,
  server text,
  name text not null,
  description text,
  price text,
  image text,
  tags jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.references (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  comment text,
  rating integer check (rating between 1 and 5),
  image text,
  created_at timestamptz not null default now()
);

create index if not exists idx_gold_game_server on public.gold(game, server);
create index if not exists idx_game_servers_game on public.game_servers(game);
create index if not exists idx_accounts_category on public.accounts(category);

-- Trigger genérico para updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_settings_updated_at on public.settings;
create trigger trg_settings_updated_at
before update on public.settings
for each row execute function public.set_updated_at();

drop trigger if exists trg_gold_categories_updated_at on public.gold_categories;
create trigger trg_gold_categories_updated_at
before update on public.gold_categories
for each row execute function public.set_updated_at();

drop trigger if exists trg_gold_updated_at on public.gold;
create trigger trg_gold_updated_at
before update on public.gold
for each row execute function public.set_updated_at();

drop trigger if exists trg_accounts_updated_at on public.accounts;
create trigger trg_accounts_updated_at
before update on public.accounts
for each row execute function public.set_updated_at();

-- RLS base: activado (las políticas de acceso se afinan en siguiente fase)
alter table public.settings enable row level security;
alter table public.gold_categories enable row level security;
alter table public.game_servers enable row level security;
alter table public.gold enable row level security;
alter table public.accounts enable row level security;
alter table public.references enable row level security;

-- Lectura pública temporal (catálogo)
drop policy if exists "public read settings" on public.settings;
create policy "public read settings" on public.settings
for select to anon using (true);

drop policy if exists "public read gold_categories" on public.gold_categories;
create policy "public read gold_categories" on public.gold_categories
for select to anon using (true);

drop policy if exists "public read game_servers" on public.game_servers;
create policy "public read game_servers" on public.game_servers
for select to anon using (true);

drop policy if exists "public read gold" on public.gold;
create policy "public read gold" on public.gold
for select to anon using (true);

drop policy if exists "public read accounts" on public.accounts;
create policy "public read accounts" on public.accounts
for select to anon using (true);

drop policy if exists "public read references" on public.references;
create policy "public read references" on public.references
for select to anon using (true);
