-- Epic Gold Shop - setup limpio para Supabase
-- Ejecutar completo en SQL Editor

create extension if not exists "pgcrypto";

-- =========================
-- TABLAS PRINCIPALES
-- =========================

create table if not exists public.settings (
  id uuid primary key default gen_random_uuid(),
  discord text,
  whatsapp text,
  tiktok text,
  email text,
  site text,
  updated_at timestamptz not null default now()
);

create table if not exists public.account_categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  created_at timestamptz not null default now()
);

create table if not exists public.game_servers (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  name text not null,
  created_at timestamptz not null default now(),
  unique (game, name)
);

create table if not exists public.gold_categories (
  id uuid primary key default gen_random_uuid(),
  name text,
  game text not null,
  server text,
  description text,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gold (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  amount text not null,
  price text not null,
  delivery text,
  stock integer not null default 0,
  status text default 'available',
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
  stock integer default 0,
  featured boolean default false,
  image text,
  tags jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Importante: campos iguales a index.html (userName, userInitial, text, date)
create table if not exists public.references (
  id uuid primary key default gen_random_uuid(),
  "userName" text not null,
  "userInitial" text,
  rating integer check (rating between 1 and 5),
  text text,
  date text,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  password_hash text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- ÍNDICES
-- =========================
create index if not exists idx_gold_game_server on public.gold(game, server);
create index if not exists idx_accounts_category on public.accounts(category);
create index if not exists idx_game_servers_game on public.game_servers(game);
create index if not exists idx_admin_users_username on public.admin_users(username);

-- =========================
-- TRIGGER updated_at
-- =========================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_settings_updated_at on public.settings;
create trigger trg_settings_updated_at before update on public.settings
for each row execute function public.set_updated_at();

drop trigger if exists trg_gold_categories_updated_at on public.gold_categories;
create trigger trg_gold_categories_updated_at before update on public.gold_categories
for each row execute function public.set_updated_at();

drop trigger if exists trg_gold_updated_at on public.gold;
create trigger trg_gold_updated_at before update on public.gold
for each row execute function public.set_updated_at();

drop trigger if exists trg_accounts_updated_at on public.accounts;
create trigger trg_accounts_updated_at before update on public.accounts
for each row execute function public.set_updated_at();

drop trigger if exists trg_admin_users_updated_at on public.admin_users;
create trigger trg_admin_users_updated_at before update on public.admin_users
for each row execute function public.set_updated_at();

-- =========================
-- RLS
-- =========================
alter table public.settings enable row level security;
alter table public.account_categories enable row level security;
alter table public.game_servers enable row level security;
alter table public.gold_categories enable row level security;
alter table public.gold enable row level security;
alter table public.accounts enable row level security;
alter table public.references enable row level security;
alter table public.admin_users enable row level security;

-- Lectura pública para la página
drop policy if exists "public_read_settings" on public.settings;
create policy "public_read_settings" on public.settings for select to anon using (true);
drop policy if exists "public_read_account_categories" on public.account_categories;
create policy "public_read_account_categories" on public.account_categories for select to anon using (true);
drop policy if exists "public_read_game_servers" on public.game_servers;
create policy "public_read_game_servers" on public.game_servers for select to anon using (true);
drop policy if exists "public_read_gold_categories" on public.gold_categories;
create policy "public_read_gold_categories" on public.gold_categories for select to anon using (true);
drop policy if exists "public_read_gold" on public.gold;
create policy "public_read_gold" on public.gold for select to anon using (true);
drop policy if exists "public_read_accounts" on public.accounts;
create policy "public_read_accounts" on public.accounts for select to anon using (true);
drop policy if exists "public_read_references" on public.references;
create policy "public_read_references" on public.references for select to anon using (true);


-- Escritura desde frontend (sin backend) para panel admin en la misma web
drop policy if exists "public_write_settings" on public.settings;
create policy "public_write_settings" on public.settings for all to anon using (true) with check (true);
drop policy if exists "public_write_account_categories" on public.account_categories;
create policy "public_write_account_categories" on public.account_categories for all to anon using (true) with check (true);
drop policy if exists "public_write_game_servers" on public.game_servers;
create policy "public_write_game_servers" on public.game_servers for all to anon using (true) with check (true);
drop policy if exists "public_write_gold_categories" on public.gold_categories;
create policy "public_write_gold_categories" on public.gold_categories for all to anon using (true) with check (true);
drop policy if exists "public_write_gold" on public.gold;
create policy "public_write_gold" on public.gold for all to anon using (true) with check (true);
drop policy if exists "public_write_accounts" on public.accounts;
create policy "public_write_accounts" on public.accounts for all to anon using (true) with check (true);
drop policy if exists "public_write_references" on public.references;
create policy "public_write_references" on public.references for all to anon using (true) with check (true);
-- Bloquear lectura de admin_users para anon
drop policy if exists "deny_anon_read_admin_users" on public.admin_users;
create policy "deny_anon_read_admin_users" on public.admin_users for select to anon using (false);

-- =========================
-- SEED BÁSICO (opcional)
-- =========================
insert into public.settings (id, discord, whatsapp, tiktok, email, site)
select gen_random_uuid(),
  'https://discord.gg/epicgoldshop',
  'https://wa.me/1234567890',
  'https://www.tiktok.com/@epicgoldshop',
  'soporte@epicgoldshop.com',
  'https://epicgoldshop.com'
where not exists (select 1 from public.settings);

insert into public.account_categories (name)
values ('Turtle WoW'), ('World of Warcraft'), ('Albion Online'), ('Runescape')
on conflict (name) do nothing;

insert into public.references (id, "userName", "userInitial", rating, text, date)
select gen_random_uuid(), r."userName", left(r."userName", 1), r.rating, r.text, to_char(current_date, 'DD/MM/YYYY')
from (
  values
    ('GamerPro', 5, 'Excelente servicio!'),
    ('WoWPlayer', 5, 'Entrega rápida y segura.')
) as r("userName", rating, text)
where not exists (
  select 1 from public.references x
  where x."userName" = r."userName" and coalesce(x.text, '') = coalesce(r.text, '')
);

-- Admin inicial (reemplazar hash)
-- node -e "const b=require('bcryptjs'); console.log(b.hashSync('TU_PASSWORD', 10))"
insert into public.admin_users (username, password_hash, is_active)
values ('admin', '$2a$10$REEMPLAZAR_POR_HASH_BCRYPT_REAL', true)
on conflict (username) do nothing;
