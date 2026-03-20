-- Schema standalone para métodos de pago
-- Pégalo completo en Supabase SQL Editor si solo quieres crear esta tabla.

create extension if not exists "pgcrypto";

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  image text,
  info_type text not null default 'payment_id',
  info_value text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_payment_methods_name_info
  on public.payment_methods(name, info_type, info_value);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_payment_methods_updated_at on public.payment_methods;
create trigger trg_payment_methods_updated_at
before update on public.payment_methods
for each row execute function public.set_updated_at();

alter table public.payment_methods enable row level security;

drop policy if exists "public read payment_methods" on public.payment_methods;
create policy "public read payment_methods" on public.payment_methods
for select to anon using (true);

drop policy if exists "anon manage payment_methods" on public.payment_methods;
create policy "anon manage payment_methods" on public.payment_methods
for all to anon using (true) with check (true);
