-- Fix específico para errores RLS/permiso en public.gold y public.settings
-- Ejecuta este script en Supabase SQL Editor.

-- 1) Asegurar RLS activo
alter table if exists public.gold enable row level security;
alter table if exists public.settings enable row level security;

-- 2) Asegurar permisos base de lectura para API roles
-- (si fueron revocados por accidente, esto los repone)
grant usage on schema public to anon, authenticated;
grant select on table public.gold to anon, authenticated;
grant select on table public.settings to anon, authenticated;

-- 3) Re-crear policies SELECT para anon (frontend)
drop policy if exists "public read gold" on public.gold;
create policy "public read gold" on public.gold
for select to anon using (true);

drop policy if exists "public read settings" on public.settings;
create policy "public read settings" on public.settings
for select to anon using (true);

-- 4) (Opcional) lectura también para authenticated
-- útil si luego usas login de Supabase user sin romper catálogo

drop policy if exists "auth read gold" on public.gold;
create policy "auth read gold" on public.gold
for select to authenticated using (true);

drop policy if exists "auth read settings" on public.settings;
create policy "auth read settings" on public.settings
for select to authenticated using (true);
