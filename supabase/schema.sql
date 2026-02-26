-- Supabase schema completo (con nombres por entidad)
-- Guarda la data de la página por secciones: accounts, gold_packages, etc.

create table if not exists public.accounts (
  id bigint primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.gold_packages (
  id bigint primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.gold_categories (
  id bigint primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.references (
  id bigint primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.site_settings (
  id integer primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  constraint site_settings_singleton check (id = 1)
);

create table if not exists public.categories (
  id integer primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  constraint categories_singleton check (id = 1)
);

create table if not exists public.game_servers (
  id integer primary key,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  constraint game_servers_singleton check (id = 1)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_accounts_updated_at on public.accounts;
create trigger set_accounts_updated_at
before update on public.accounts
for each row execute function public.set_updated_at();

drop trigger if exists set_gold_packages_updated_at on public.gold_packages;
create trigger set_gold_packages_updated_at
before update on public.gold_packages
for each row execute function public.set_updated_at();

drop trigger if exists set_gold_categories_updated_at on public.gold_categories;
create trigger set_gold_categories_updated_at
before update on public.gold_categories
for each row execute function public.set_updated_at();

drop trigger if exists set_references_updated_at on public.references;
create trigger set_references_updated_at
before update on public.references
for each row execute function public.set_updated_at();

drop trigger if exists set_site_settings_updated_at on public.site_settings;
create trigger set_site_settings_updated_at
before update on public.site_settings
for each row execute function public.set_updated_at();

drop trigger if exists set_categories_updated_at on public.categories;
create trigger set_categories_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

drop trigger if exists set_game_servers_updated_at on public.game_servers;
create trigger set_game_servers_updated_at
before update on public.game_servers
for each row execute function public.set_updated_at();

alter table public.accounts enable row level security;
alter table public.gold_packages enable row level security;
alter table public.gold_categories enable row level security;
alter table public.references enable row level security;
alter table public.site_settings enable row level security;
alter table public.categories enable row level security;
alter table public.game_servers enable row level security;

-- Configuración rápida para arrancar: lectura/escritura pública con anon key.
-- Para producción, reemplaza estas policies por auth/admin.
drop policy if exists "public all accounts" on public.accounts;
create policy "public all accounts" on public.accounts
for all using (true) with check (true);

drop policy if exists "public all gold_packages" on public.gold_packages;
create policy "public all gold_packages" on public.gold_packages
for all using (true) with check (true);

drop policy if exists "public all gold_categories" on public.gold_categories;
create policy "public all gold_categories" on public.gold_categories
for all using (true) with check (true);

drop policy if exists "public all references" on public.references;
create policy "public all references" on public.references
for all using (true) with check (true);

drop policy if exists "public all site_settings" on public.site_settings;
create policy "public all site_settings" on public.site_settings
for all using (true) with check (true);

drop policy if exists "public all categories" on public.categories;
create policy "public all categories" on public.categories
for all using (true) with check (true);

drop policy if exists "public all game_servers" on public.game_servers;
create policy "public all game_servers" on public.game_servers
for all using (true) with check (true);
