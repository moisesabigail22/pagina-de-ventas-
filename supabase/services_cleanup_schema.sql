-- Limpieza de servicios duplicados y servicios sin imagen.
-- Pega este script completo en Supabase SQL Editor.

begin;

alter table if exists public.services
  add column if not exists image text;

-- Normalizar textos base para que la deduplicación sea consistente.
update public.services
set
  category = nullif(trim(category), ''),
  game = nullif(trim(game), ''),
  name = trim(name),
  description = nullif(trim(description), ''),
  image = nullif(trim(image), ''),
  updated_at = now()
where
  category is distinct from nullif(trim(category), '')
  or game is distinct from nullif(trim(game), '')
  or name is distinct from trim(name)
  or description is distinct from nullif(trim(description), '')
  or image is distinct from nullif(trim(image), '');

-- Rellenar imágenes faltantes con una imagen pública por defecto.
update public.services
set
  image = 'https://i.imgur.com/ynvAS9B.png',
  updated_at = now()
where coalesce(trim(image), '') = '';

-- Eliminar duplicados conservando la fila más útil:
-- 1) con imagen
-- 2) con descripción
-- 3) más reciente
with ranked as (
  select
    id,
    row_number() over (
      partition by
        lower(trim(coalesce(category, ''))),
        lower(trim(coalesce(game, ''))),
        lower(trim(name))
      order by
        case when coalesce(trim(image), '') <> '' then 0 else 1 end,
        case when coalesce(trim(description), '') <> '' then 0 else 1 end,
        updated_at desc nulls last,
        created_at desc nulls last,
        id desc
    ) as rn
  from public.services
)
delete from public.services s
using ranked r
where s.id = r.id
  and r.rn > 1;

-- Evitar que vuelvan a entrar duplicados por categoría + juego + nombre.
create unique index if not exists uq_services_category_game_name_normalized
  on public.services (
    lower(trim(coalesce(category, ''))),
    lower(trim(coalesce(game, ''))),
    lower(trim(name))
  );

commit;

-- Verificación rápida.
select
  count(*) as total_servicios,
  count(*) filter (where coalesce(trim(image), '') = '') as servicios_sin_imagen
from public.services;
