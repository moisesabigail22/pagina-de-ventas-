-- Schema + seed para cargar portadas exactas de servicios en Supabase
-- 1) Ejecuta este archivo si tu tabla public.services todavía no tiene la columna image
-- 2) Reemplaza cada URL por la portada real que te pasó el diseñador/cliente

alter table if exists public.services
  add column if not exists image text;

with source(category, game, name, description, price, image) as (
  values
    ('boosteo', 'WoW Privado', 'Boosting EPIC', 'Boosteo manual, niveles personalizados y soporte por región.', 280, 'https://TU-URL/boosting-epic.jpg'),
    ('profesiones', 'WoW', 'Alchemy EPIC 1-375', 'Subida manual de Alquimia del 1 al 375.', 40, 'https://TU-URL/alchemy-epic.jpg'),
    ('profesiones', 'WoW', 'Blacksmithing EPIC 1-375', 'Subida manual de Herrería del 1 al 375.', 50, 'https://TU-URL/blacksmithing-epic.jpg'),
    ('profesiones', 'WoW', 'Cooking EPIC 1-375', 'Subida manual de Cocina del 1 al 375.', 30, 'https://TU-URL/cooking-epic.jpg'),
    ('profesiones', 'WoW', 'Enchanting EPIC 1-375', 'Subida manual de Encantamiento del 1 al 375.', 40, 'https://TU-URL/enchanting-epic.jpg'),
    ('profesiones', 'WoW', 'Fishing EPIC 1-375', 'Subida manual de Pesca del 1 al 375.', 40, 'https://TU-URL/fishing-epic.jpg'),
    ('profesiones', 'WoW', 'Herbalism EPIC 1-375', 'Subida manual de Herboristería del 1 al 375.', 30, 'https://TU-URL/herbalism-epic.jpg'),
    ('profesiones', 'WoW', 'Jewelcrafting EPIC 1-375', 'Subida manual de Joyería del 1 al 375.', 50, 'https://TU-URL/jewelcrafting-epic.jpg'),
    ('profesiones', 'WoW', 'Mining EPIC 1-375', 'Subida manual de Minería del 1 al 375.', 30, 'https://TU-URL/mining-epic.jpg'),
    ('profesiones', 'WoW', 'Skinning EPIC 1-375', 'Subida manual de Desuello del 1 al 375.', 30, 'https://TU-URL/skinning-epic.jpg')
)
update public.services s
set
  description = src.description,
  price = src.price,
  image = src.image,
  updated_at = now()
from source src
where coalesce(s.category, '') = coalesce(src.category, '')
  and coalesce(s.game, '') = coalesce(src.game, '')
  and s.name = src.name;

with source(category, game, name, description, price, image) as (
  values
    ('boosteo', 'WoW Privado', 'Boosting EPIC', 'Boosteo manual, niveles personalizados y soporte por región.', 280, 'https://TU-URL/boosting-epic.jpg'),
    ('profesiones', 'WoW', 'Alchemy EPIC 1-375', 'Subida manual de Alquimia del 1 al 375.', 40, 'https://TU-URL/alchemy-epic.jpg'),
    ('profesiones', 'WoW', 'Blacksmithing EPIC 1-375', 'Subida manual de Herrería del 1 al 375.', 50, 'https://TU-URL/blacksmithing-epic.jpg'),
    ('profesiones', 'WoW', 'Cooking EPIC 1-375', 'Subida manual de Cocina del 1 al 375.', 30, 'https://TU-URL/cooking-epic.jpg'),
    ('profesiones', 'WoW', 'Enchanting EPIC 1-375', 'Subida manual de Encantamiento del 1 al 375.', 40, 'https://TU-URL/enchanting-epic.jpg'),
    ('profesiones', 'WoW', 'Fishing EPIC 1-375', 'Subida manual de Pesca del 1 al 375.', 40, 'https://TU-URL/fishing-epic.jpg'),
    ('profesiones', 'WoW', 'Herbalism EPIC 1-375', 'Subida manual de Herboristería del 1 al 375.', 30, 'https://TU-URL/herbalism-epic.jpg'),
    ('profesiones', 'WoW', 'Jewelcrafting EPIC 1-375', 'Subida manual de Joyería del 1 al 375.', 50, 'https://TU-URL/jewelcrafting-epic.jpg'),
    ('profesiones', 'WoW', 'Mining EPIC 1-375', 'Subida manual de Minería del 1 al 375.', 30, 'https://TU-URL/mining-epic.jpg'),
    ('profesiones', 'WoW', 'Skinning EPIC 1-375', 'Subida manual de Desuello del 1 al 375.', 30, 'https://TU-URL/skinning-epic.jpg')
)
insert into public.services (category, game, name, description, price, image)
select src.category, src.game, src.name, src.description, src.price, src.image
from source src
where not exists (
  select 1
  from public.services s
  where coalesce(s.category, '') = coalesce(src.category, '')
    and coalesce(s.game, '') = coalesce(src.game, '')
    and s.name = src.name
);
