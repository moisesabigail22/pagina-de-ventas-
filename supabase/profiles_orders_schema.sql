-- ============================================================
-- Epic Gold Shop
-- Schema separado para perfiles de cliente y órdenes
-- Pega este archivo en Supabase SQL Editor
-- ============================================================

create extension if not exists "pgcrypto";

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

create index if not exists idx_orders_user_id on public.orders(user_id);
create index if not exists idx_orders_created_at on public.orders(created_at desc);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.orders enable row level security;

drop policy if exists "users manage own profile" on public.profiles;
create policy "users manage own profile" on public.profiles
for all to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "users read own orders" on public.orders;
create policy "users read own orders" on public.orders
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "users insert own orders" on public.orders;
create policy "users insert own orders" on public.orders
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "users update own orders" on public.orders;
create policy "users update own orders" on public.orders
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
