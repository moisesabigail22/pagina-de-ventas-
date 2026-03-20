-- =========================================================
-- EPIC GOLD SHOP
-- Schema standalone para:
-- 1) métodos de pago con imagen
-- 2) compatibilidad segura en bases ya creadas
-- =========================================================
--
-- NOTA IMPORTANTE:
-- El formulario de oro ahora pide:
-- - correo o Discord del comprador
-- - capture/comprobante de la transacción
--
-- Esos 2 datos NO necesitan columna nueva en la base porque
-- se envían directo a la Edge Function `create-gold-ticket`
-- y desde ahí se mandan al ticket privado de Discord.
--
-- Lo que sí necesita schema en base es `payment_methods`,
-- para guardar nombre, imagen, tipo de dato e información.
-- =========================================================

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

alter table if exists public.payment_methods
  add column if not exists image text,
  add column if not exists info_type text default 'payment_id',
  add column if not exists info_value text;

update public.payment_methods
set info_type = coalesce(nullif(trim(info_type), ''), 'payment_id')
where info_type is null or trim(info_type) = '';

update public.payment_methods
set info_value = coalesce(info_value, '')
where info_value is null;

alter table public.payment_methods
  alter column info_type set default 'payment_id';

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

comment on table public.payment_methods is
'Métodos de pago del panel admin. image puede guardar URL pública o data URL/base64.';

comment on column public.payment_methods.image is
'Logo o imagen del método de pago. Acepta URL o imagen subida convertida a data URL.';

comment on column public.payment_methods.info_type is
'Tipo de información a mostrar al cliente: payment_id o email.';

comment on column public.payment_methods.info_value is
'Valor mostrado al cliente: correo o ID del método de pago.';

select
  'payment_methods' as tabla,
  count(*) as total
from public.payment_methods;
