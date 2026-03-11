-- Parte 3: seguridad (RLS) + admin writer por API
-- Ejecuta esto DESPUÉS de supabase/schema.sql

-- 1) Crear tabla de admins (credenciales del panel)
create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  password_hash text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_admin_users_username on public.admin_users(username);

-- Trigger updated_at para admin_users
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_admin_users_updated_at on public.admin_users;
create trigger trg_admin_users_updated_at
before update on public.admin_users
for each row execute function public.set_updated_at();

-- 2) Activar RLS en admin_users y BLOQUEAR TODO a anon
alter table public.admin_users enable row level security;

drop policy if exists "no anon read admin_users" on public.admin_users;
create policy "no anon read admin_users"
on public.admin_users
for select
to anon
using (false);

-- No creamos policies de insert/update/delete para anon.
-- Las escrituras del panel se harán desde backend con service_role.

-- 3) Mantener lectura pública del catálogo (si la quieres)
-- Si quieres cerrar lectura pública, elimina estas políticas del schema base.

-- 4) Seed inicial de admin (CAMBIA el hash por uno real de bcrypt)
-- Ejemplo: genera hash con Node
-- node -e "const b=require('bcryptjs'); console.log(b.hashSync('TU_PASSWORD', 10))"

insert into public.admin_users (username, password_hash, is_active)
values ('admin', '$2a$10$REEMPLAZAR_POR_HASH_BCRYPT_REAL', true)
on conflict (username) do nothing;
