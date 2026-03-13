-- Seed robusto para catálogo de ORO + SERVICIOS.
-- No requiere índices UNIQUE para funcionar (evita ON CONFLICT).

begin;

-- ==========================================
-- 1) GOLD CATEGORIES (solo oro)
-- ==========================================
with src(game, server, description, image) as (
  values
    ('WoW Turtle'::text, null::text, 'Oro para Turtle WoW'::text, 'https://i.imgur.com/ynvAS9B.png'::text),
    ('Servidores Privados', null::text, 'Oro para servidores privados de WoW', 'https://i.imgur.com/ynvAS9B.png'),
    ('WoW Oficial', null::text, 'Oro para servidores oficiales de WoW', 'https://i.imgur.com/ynvAS9B.png')
)
update public.gold_categories gc
set description = src.description,
    image = src.image,
    updated_at = now()
from src
where gc.game = src.game
  and coalesce(gc.server, '') = coalesce(src.server, '');

insert into public.gold_categories (game, server, description, image)
select src.game, src.server, src.description, src.image
from (
  values
    ('WoW Turtle'::text, null::text, 'Oro para Turtle WoW'::text, 'https://i.imgur.com/ynvAS9B.png'::text),
    ('Servidores Privados', null::text, 'Oro para servidores privados de WoW', 'https://i.imgur.com/ynvAS9B.png'),
    ('WoW Oficial', null::text, 'Oro para servidores oficiales de WoW', 'https://i.imgur.com/ynvAS9B.png')
) as src(game, server, description, image)
where not exists (
  select 1
  from public.gold_categories gc
  where gc.game = src.game
    and coalesce(gc.server, '') = coalesce(src.server, '')
);

-- ==========================================
-- 2) GAME SERVERS (solo oro)
-- ==========================================
with src(game, name) as (
  values
    ('WoW Turtle'::text, 'Ambershire'::text),
    ('WoW Turtle', 'Nordanaar'),
    ('WoW Turtle', 'Telabim'),
    ('Servidores Privados', 'Bronzebeard'),
    ('Servidores Privados', 'South Sea'),
    ('Servidores Privados', 'Warmane Onyxia'),
    ('Servidores Privados', 'Project Epoch - Kezan'),
    ('Servidores Privados', 'Project Epoch - Gurubashi'),
    ('WoW Oficial', 'Nightslayer A/H')
)
insert into public.game_servers (game, name)
select src.game, src.name
from src
where not exists (
  select 1
  from public.game_servers gs
  where gs.game = src.game
    and gs.name = src.name
);

-- ==========================================
-- 3) GOLD PACKAGES (solo oro)
-- ==========================================
with src(game, server, amount, price) as (
  values
    ('WoW Turtle'::text, 'Ambershire'::text, 100::integer, 3.00::numeric),
    ('WoW Turtle', 'Nordanaar', 100, 2.90),
    ('WoW Turtle', 'Telabim', 100, 4.50),
    ('Servidores Privados', 'Bronzebeard', 100, 3.50),
    ('Servidores Privados', 'South Sea', 100, 4.50),
    ('Servidores Privados', 'Warmane Onyxia', 1000, 2.00),
    ('Servidores Privados', 'Project Epoch - Kezan', 100, 4.00),
    ('Servidores Privados', 'Project Epoch - Gurubashi', 100, 3.00)
)
update public.gold g
set price = src.price,
    updated_at = now()
from src
where g.game = src.game
  and g.server = src.server
  and g.amount::text = src.amount::text;

insert into public.gold (game, server, amount, price)
select src.game, src.server, src.amount, src.price
from (
  values
    ('WoW Turtle'::text, 'Ambershire'::text, 100::integer, 3.00::numeric),
    ('WoW Turtle', 'Nordanaar', 100, 2.90),
    ('WoW Turtle', 'Telabim', 100, 4.50),
    ('Servidores Privados', 'Bronzebeard', 100, 3.50),
    ('Servidores Privados', 'South Sea', 100, 4.50),
    ('Servidores Privados', 'Warmane Onyxia', 1000, 2.00),
    ('Servidores Privados', 'Project Epoch - Kezan', 100, 4.00),
    ('Servidores Privados', 'Project Epoch - Gurubashi', 100, 3.00)
) as src(game, server, amount, price)
where not exists (
  select 1
  from public.gold g
  where g.game = src.game
    and g.server = src.server
    and g.amount::text = src.amount::text
);

-- ==========================================
-- 4) SERVICES (visibles al público + admin)
-- ==========================================
alter table if exists public.services
  add column if not exists image text;

with src(category, game, name, description, price, image) as (
  values
    ('boosteo'::text, 'WoW Privado'::text, 'Boosting EPIC'::text, 'Boosteo manual, niveles personalizados, soporte por región.', 280.00::numeric, 'https://i.imgur.com/ynvAS9B.png'::text),
    ('profesiones', 'WoW', 'Alchemy Epic 1-375', 'Subida manual de Alquimia 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Blacksmithing Epic 1-375', 'Subida manual de Herrería 1-375.', 50.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Cooking Epic 1-375', 'Subida manual de Cocina 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Enchanting Epic 1-375', 'Subida manual de Encantamiento 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Fishing Epic 1-375', 'Subida manual de Pesca 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Herbalism Epic 1-375', 'Subida manual de Herboristería 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Jewelcrafting Epic 1-375', 'Subida manual de Joyería 1-375.', 50.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Mining Epic 1-375', 'Subida manual de Minería 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Skinning Epic 1-375', 'Subida manual de Desuello 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png')
)
update public.services s
set description = src.description,
    price = src.price,
    image = src.image,
    updated_at = now()
from src
where s.category = src.category
  and s.game = src.game
  and s.name = src.name;

insert into public.services (category, game, name, description, price, image)
select src.category, src.game, src.name, src.description, src.price, src.image
from (
  values
    ('boosteo'::text, 'WoW Privado'::text, 'Boosting EPIC'::text, 'Boosteo manual, niveles personalizados, soporte por región.', 280.00::numeric, 'https://i.imgur.com/ynvAS9B.png'::text),
    ('profesiones', 'WoW', 'Alchemy Epic 1-375', 'Subida manual de Alquimia 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Blacksmithing Epic 1-375', 'Subida manual de Herrería 1-375.', 50.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Cooking Epic 1-375', 'Subida manual de Cocina 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Enchanting Epic 1-375', 'Subida manual de Encantamiento 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Fishing Epic 1-375', 'Subida manual de Pesca 1-375.', 40.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Herbalism Epic 1-375', 'Subida manual de Herboristería 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Jewelcrafting Epic 1-375', 'Subida manual de Joyería 1-375.', 50.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Mining Epic 1-375', 'Subida manual de Minería 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png'),
    ('profesiones', 'WoW', 'Skinning Epic 1-375', 'Subida manual de Desuello 1-375.', 30.00, 'https://i.imgur.com/ynvAS9B.png')
) as src(category, game, name, description, price, image)
where not exists (
  select 1
  from public.services s
  where s.category = src.category
    and s.game = src.game
    and s.name = src.name
);


-- Asegurar lectura pública de servicios para el frontend (anon)
alter table if exists public.services enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'services'
      and policyname = 'public read services'
  ) then
    create policy "public read services" on public.services
      for select to anon using (true);
  end if;
end $$;

commit;
