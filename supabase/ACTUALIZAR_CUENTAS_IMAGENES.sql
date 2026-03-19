-- Ejecuta este archivo en Supabase SQL Editor para asegurar la columna de imagen
-- en la tabla public.accounts y limpiar valores vacíos.

alter table if exists public.accounts
  add column if not exists image text;

update public.accounts
set image = null
where trim(coalesce(image, '')) = '';

comment on column public.accounts.image is 'URL pública o data URL de la imagen usada para mostrar la cuenta en la tienda.';
