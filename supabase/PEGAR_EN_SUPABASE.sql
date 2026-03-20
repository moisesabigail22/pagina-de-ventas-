-- ============================================================
-- PEGAR EN SUPABASE SQL EDITOR (archivo único)
-- Reemplaza SOLO el bloque BACKUP_JSON por tu backup completo.
-- ============================================================

begin;

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
  name text,
  game text not null,
  server text,
  description text,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.gold_categories
  add column if not exists name text;

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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.gold
  drop column if exists delivery,
  drop column if exists stock;

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

alter table if exists public.accounts
  add column if not exists image text;

create table if not exists public.account_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_references (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  comment text,
  rating integer check (rating between 1 and 5),
  image text,
  created_at timestamptz not null default now()
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  category text,
  game text,
  name text not null,
  description text,
  price numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image text,
  info_type text not null default 'payment_id',
  info_value text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_type text not null,
  title text not null,
  summary text,
  status text not null default 'ticket_creado',
  discord_url text,
  discord_channel_id text,
  order_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create temporary table if not exists tmp_backup_payload(payload jsonb) on commit drop;
truncate tmp_backup_payload;

-- ==============================
-- BACKUP_JSON: PEGA TU JSON AQUÍ
-- ==============================
insert into tmp_backup_payload(payload)
values (
$backup$
{
  "epicgoldshop_settings": "{}",
  "epicgoldshop_gold_categories": "[]",
  "epicgoldshop_game_servers": "[]",
  "epicgoldshop_gold": "[]",
  "epicgoldshop_accounts": "[]",
  "epicgoldshop_references": "[]",
  "epicgoldshop_categories": "[]",
  "epicgoldshop_payment_methods": "[]"
}
$backup$::jsonb
);

-- Limpia tablas para restaurar exactamente tu backup
truncate table
  public.gold,
  public.gold_categories,
  public.game_servers,
  public.accounts,
  public.account_categories,
  public.customer_references,
  public.settings,
  public.services,
  public.payment_methods,
  public.orders
restart identity;

-- settings
insert into public.settings (discord, whatsapp, tiktok, email, site)
select
  (t.payload->>'epicgoldshop_settings')::jsonb->>'discord',
  (t.payload->>'epicgoldshop_settings')::jsonb->>'whatsapp',
  (t.payload->>'epicgoldshop_settings')::jsonb->>'tiktok',
  (t.payload->>'epicgoldshop_settings')::jsonb->>'email',
  (t.payload->>'epicgoldshop_settings')::jsonb->>'site'
from tmp_backup_payload t;

-- gold_categories
insert into public.gold_categories (name, game, server, description, image)
select
  coalesce(nullif(x->>'name', ''), x->>'game'),
  x->>'game',
  x->>'server',
  x->>'description',
  x->>'image'
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_gold_categories')::jsonb, '[]'::jsonb)) x;

-- game_servers
insert into public.game_servers (game, name)
select
  x->>'game',
  x->>'name'
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_game_servers')::jsonb, '[]'::jsonb)) x;

-- gold
insert into public.gold (game, server, amount, price)
select
  x->>'game',
  x->>'server',
  coalesce(nullif(x->>'amount','')::integer, 0),
  coalesce(nullif(x->>'price','')::numeric, 0)
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_gold')::jsonb, '[]'::jsonb)) x;

-- accounts
insert into public.accounts (type, category, server, name, description, price, image, tags)
select
  coalesce(x->>'type', 'account'),
  x->>'category',
  x->>'server',
  coalesce(x->>'name', 'Cuenta'),
  x->>'description',
  x->>'price',
  x->>'image',
  coalesce(x->'tags', '[]'::jsonb)
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_accounts')::jsonb, '[]'::jsonb)) x;

-- account_categories
insert into public.account_categories (name)
select distinct trim(value #>> '{}')
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_categories')::jsonb, '[]'::jsonb)) value
where coalesce(trim(value #>> '{}'), '') <> '';

insert into public.account_categories (name)
select distinct trim(x->>'category')
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_accounts')::jsonb, '[]'::jsonb)) x
where coalesce(trim(x->>'category'), '') <> ''
on conflict (name) do nothing;

-- customer_references (soporta name/comment o userName/text)
insert into public.customer_references (name, comment, rating, image)
select
  coalesce(x->>'name', x->>'userName', 'Cliente'),
  coalesce(x->>'comment', x->>'text', ''),
  case
    when nullif(x->>'rating','') is null then null
    else (x->>'rating')::integer
  end,
  x->>'image'
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_references')::jsonb, '[]'::jsonb)) x;

-- services (si existe en backup)
insert into public.services (category, game, name, description, price)
select
  x->>'category',
  x->>'game',
  coalesce(x->>'name', 'Servicio'),
  x->>'description',
  coalesce(nullif(x->>'price','')::numeric, 0)
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_services')::jsonb, '[]'::jsonb)) x;

-- payment_methods (si existe en backup)
insert into public.payment_methods (name, image, info_type, info_value)
select
  coalesce(x->>'name', 'Método'),
  x->>'image',
  coalesce(nullif(x->>'infoType', ''), 'payment_id'),
  coalesce(x->>'infoValue', '')
from tmp_backup_payload t,
jsonb_array_elements(coalesce((t.payload->>'epicgoldshop_payment_methods')::jsonb, '[]'::jsonb)) x;

commit;

-- Verificación final
select 'settings' as table_name, count(*) as total from public.settings
union all select 'gold_categories', count(*) from public.gold_categories
union all select 'game_servers', count(*) from public.game_servers
union all select 'gold', count(*) from public.gold
union all select 'accounts', count(*) from public.accounts
union all select 'account_categories', count(*) from public.account_categories
union all select 'customer_references', count(*) from public.customer_references
union all select 'services', count(*) from public.services
union all select 'payment_methods', count(*) from public.payment_methods
union all select 'profiles', count(*) from public.profiles
union all select 'orders', count(*) from public.orders
order by table_name;


-- Escritura desde el panel actual (cliente con anon key)
drop policy if exists "anon manage settings" on public.settings;
create policy "anon manage settings" on public.settings
for all to anon using (true) with check (true);

drop policy if exists "anon manage gold_categories" on public.gold_categories;
create policy "anon manage gold_categories" on public.gold_categories
for all to anon using (true) with check (true);

drop policy if exists "anon manage game_servers" on public.game_servers;
create policy "anon manage game_servers" on public.game_servers
for all to anon using (true) with check (true);

drop policy if exists "anon manage gold" on public.gold;
create policy "anon manage gold" on public.gold
for all to anon using (true) with check (true);

drop policy if exists "anon manage accounts" on public.accounts;
create policy "anon manage accounts" on public.accounts
for all to anon using (true) with check (true);

drop policy if exists "anon manage account_categories" on public.account_categories;
create policy "anon manage account_categories" on public.account_categories
for all to anon using (true) with check (true);

drop policy if exists "anon manage services" on public.services;
create policy "anon manage services" on public.services
for all to anon using (true) with check (true);

drop policy if exists "anon manage payment_methods" on public.payment_methods;
create policy "anon manage payment_methods" on public.payment_methods
for all to anon using (true) with check (true);

drop policy if exists "anon manage customer_references" on public.customer_references;
create policy "anon manage customer_references" on public.customer_references
for all to anon using (true) with check (true);
