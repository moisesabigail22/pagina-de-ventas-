-- Setup ULTRA SIMPLE para Supabase (sin backend)
-- Guarda toda la página en 1 sola fila JSON.

create extension if not exists "pgcrypto";

create table if not exists public.app_state (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_app_state_updated_at on public.app_state;
create trigger trg_app_state_updated_at
before update on public.app_state
for each row execute function public.set_updated_at();

alter table public.app_state enable row level security;

drop policy if exists "public_read_app_state" on public.app_state;
create policy "public_read_app_state" on public.app_state
for select to anon
using (true);

drop policy if exists "public_write_app_state" on public.app_state;
create policy "public_write_app_state" on public.app_state
for all to anon
using (true)
with check (true);

insert into public.app_state (id, data)
values ('main', '{}'::jsonb)
on conflict (id) do nothing;
