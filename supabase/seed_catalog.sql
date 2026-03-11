-- Seed y verificación para anclar catálogo en Supabase
-- Ejecutar DESPUÉS de supabase/schema.sql
-- Este seed NO depende de ON CONFLICT para evitar errores 42P10.

begin;

-- SETTINGS (mantiene 1 registro principal; actualiza si existe, inserta si no existe)
with desired as (
  select
    'https://discord.gg/AYJkmeZn'::text as discord,
    'https://wa.me/1234567890'::text as whatsapp,
    'https://www.tiktok.com/@farmers.de.mmorpg'::text as tiktok,
    'soporte@epicgoldshop.com'::text as email,
    'https://www.epicgoldshop.com'::text as site
), first_row as (
  select id from public.settings order by updated_at desc, id desc limit 1
)
update public.settings s
set
  discord = d.discord,
  whatsapp = d.whatsapp,
  tiktok = d.tiktok,
  email = d.email,
  site = d.site,
  updated_at = now()
from desired d
where s.id in (select id from first_row);

insert into public.settings (discord, whatsapp, tiktok, email, site)
select d.discord, d.whatsapp, d.tiktok, d.email, d.site
from (
  select
    'https://discord.gg/AYJkmeZn'::text as discord,
    'https://wa.me/1234567890'::text as whatsapp,
    'https://www.tiktok.com/@farmers.de.mmorpg'::text as tiktok,
    'soporte@epicgoldshop.com'::text as email,
    'https://www.epicgoldshop.com'::text as site
) d
where not exists (select 1 from public.settings);

-- CATEGORÍAS DE ORO
with source(game, server, description, image) as (
  values
    ('WoW Turtle', 'Nordanaar', 'Gold para Turtle WoW en servidores Ambershire, Nordanaar, Telabim y South Sea.', 'https://i.imgur.com/wwQK4J5.jpeg'),
    ('WoW Privado', 'Warmane', 'Gold para servidores privados incluyendo Bronzebeard, Warmane y Project Epoch.', 'https://i.imgur.com/E3a0Q5L.jpeg'),
    ('WoW Oficial', 'Nightslayer A/H', 'Gold para servidor oficial con stock verificado.', 'https://i.imgur.com/5Yh4leB.jpeg')
)
update public.gold_categories gc
set
  description = s.description,
  image = s.image,
  updated_at = now()
from source s
where gc.game = s.game and coalesce(gc.server, '') = coalesce(s.server, '');

with source(game, server, description, image) as (
  values
    ('WoW Turtle', 'Nordanaar', 'Gold para Turtle WoW en servidores Ambershire, Nordanaar, Telabim y South Sea.', 'https://i.imgur.com/wwQK4J5.jpeg'),
    ('WoW Privado', 'Warmane', 'Gold para servidores privados incluyendo Bronzebeard, Warmane y Project Epoch.', 'https://i.imgur.com/E3a0Q5L.jpeg'),
    ('WoW Oficial', 'Nightslayer A/H', 'Gold para servidor oficial con stock verificado.', 'https://i.imgur.com/5Yh4leB.jpeg')
)
insert into public.gold_categories (game, server, description, image)
select s.game, s.server, s.description, s.image
from source s
where not exists (
  select 1
  from public.gold_categories gc
  where gc.game = s.game and coalesce(gc.server, '') = coalesce(s.server, '')
);

-- SERVIDORES
with source(game, name) as (
  values
    ('WoW Turtle', 'Ambershire'),
    ('WoW Turtle', 'Nordanaar'),
    ('WoW Turtle', 'Telabim'),
    ('WoW Turtle', 'South Sea'),
    ('WoW Privado', 'Bronzebeard'),
    ('WoW Privado', 'Warmane'),
    ('WoW Privado', 'Project Epoch - Kezan'),
    ('WoW Privado', 'Project Epoch - Gurubashi'),
    ('WoW Oficial', 'Nightslayer A/H')
)
insert into public.game_servers (game, name)
select s.game, s.name
from source s
where not exists (
  select 1
  from public.game_servers gs
  where gs.game = s.game and gs.name = s.name
);

-- ORO (compatibilidad: amount puede ser INTEGER o TEXT según esquema previo)
do $$
declare
  amount_type text;
begin
  select c.data_type
  into amount_type
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'gold'
    and c.column_name = 'amount'
  limit 1;

  if amount_type = 'text' then
    with source(game, server, amount_text, price, delivery, stock) as (
      values
        ('WoW Turtle', 'Ambershire', '100', 3.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Nordanaar', '100', 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Telabim', '100', 4.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'South Sea', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Bronzebeard', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Warmane', '1000', 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Kezan', '100', 4.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Gurubashi', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '100', 5.80, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '200', 11.60, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '300', 17.40, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '500', 29.00, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '1000', 58.00, '15-40 minutos', 'Disponible')
    )
    update public.gold g
    set
      price = s.price,
      delivery = s.delivery,
      stock = s.stock,
      updated_at = now()
    from source s
    where g.game = s.game
      and g.server = s.server
      and g.amount = s.amount_text;

    with source(game, server, amount_text, price, delivery, stock) as (
      values
        ('WoW Turtle', 'Ambershire', '100', 3.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Nordanaar', '100', 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Telabim', '100', 4.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'South Sea', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Bronzebeard', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Warmane', '1000', 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Kezan', '100', 4.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Gurubashi', '100', 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '100', 5.80, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '200', 11.60, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '300', 17.40, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '500', 29.00, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', '1000', 58.00, '15-40 minutos', 'Disponible')
    )
    insert into public.gold (game, server, amount, price, delivery, stock)
    select s.game, s.server, s.amount_text, s.price, s.delivery, s.stock
    from source s
    where not exists (
      select 1
      from public.gold g
      where g.game = s.game
        and g.server = s.server
        and g.amount = s.amount_text
    );
  else
    with source(game, server, amount_int, price, delivery, stock) as (
      values
        ('WoW Turtle', 'Ambershire', 100, 3.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Nordanaar', 100, 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Telabim', 100, 4.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'South Sea', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Bronzebeard', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Warmane', 1000, 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Kezan', 100, 4.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Gurubashi', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 100, 5.80, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 200, 11.60, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 300, 17.40, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 500, 29.00, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 1000, 58.00, '15-40 minutos', 'Disponible')
    )
    update public.gold g
    set
      price = s.price,
      delivery = s.delivery,
      stock = s.stock,
      updated_at = now()
    from source s
    where g.game = s.game
      and g.server = s.server
      and g.amount = s.amount_int;

    with source(game, server, amount_int, price, delivery, stock) as (
      values
        ('WoW Turtle', 'Ambershire', 100, 3.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Nordanaar', 100, 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'Telabim', 100, 4.50, '5-20 minutos', 'Disponible'),
        ('WoW Turtle', 'South Sea', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Bronzebeard', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Warmane', 1000, 2.50, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Kezan', 100, 4.00, '5-20 minutos', 'Disponible'),
        ('WoW Privado', 'Project Epoch - Gurubashi', 100, 3.00, '5-20 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 100, 5.80, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 200, 11.60, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 300, 17.40, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 500, 29.00, '15-40 minutos', 'Disponible'),
        ('WoW Oficial', 'Nightslayer A/H', 1000, 58.00, '15-40 minutos', 'Disponible')
    )
    insert into public.gold (game, server, amount, price, delivery, stock)
    select s.game, s.server, s.amount_int, s.price, s.delivery, s.stock
    from source s
    where not exists (
      select 1
      from public.gold g
      where g.game = s.game
        and g.server = s.server
        and g.amount = s.amount_int
    );
  end if;
end $$;

-- SERVICIOS
with source(category, game, name, description, price) as (
  values
    ('Boosteo', 'WoW Privado', 'Boosteo cualquier clase', 'Subida de personaje para cualquier clase en WoW privado.', 140),
    ('Profesiones', 'WoW', 'Herboristería / Minería', 'Subida completa de profesión', 30),
    ('Profesiones', 'WoW', 'Sastrería', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Cocina', 'Subida completa de profesión', 30),
    ('Profesiones', 'WoW', 'Pesca', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Peletería', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Encantamiento', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Herrería', 'Subida completa de profesión', 50),
    ('Profesiones', 'WoW', 'Ingeniería', 'Subida completa de profesión', 55),
    ('Profesiones', 'WoW', 'Alquimia', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Crafting', 'Subida completa de profesión', 50),
    ('Profesiones', 'WoW', 'Desuello', 'Subida completa de profesión', 30),
    ('PVP', 'WoW', 'PVP Rank Boosting', 'Servicio por rango', 15)
)
update public.services sv
set
  description = s.description,
  price = s.price,
  updated_at = now()
from source s
where coalesce(sv.category, '') = coalesce(s.category, '')
  and coalesce(sv.game, '') = coalesce(s.game, '')
  and sv.name = s.name;

with source(category, game, name, description, price) as (
  values
    ('Boosteo', 'WoW Privado', 'Boosteo cualquier clase', 'Subida de personaje para cualquier clase en WoW privado.', 140),
    ('Profesiones', 'WoW', 'Herboristería / Minería', 'Subida completa de profesión', 30),
    ('Profesiones', 'WoW', 'Sastrería', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Cocina', 'Subida completa de profesión', 30),
    ('Profesiones', 'WoW', 'Pesca', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Peletería', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Encantamiento', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Herrería', 'Subida completa de profesión', 50),
    ('Profesiones', 'WoW', 'Ingeniería', 'Subida completa de profesión', 55),
    ('Profesiones', 'WoW', 'Alquimia', 'Subida completa de profesión', 40),
    ('Profesiones', 'WoW', 'Crafting', 'Subida completa de profesión', 50),
    ('Profesiones', 'WoW', 'Desuello', 'Subida completa de profesión', 30),
    ('PVP', 'WoW', 'PVP Rank Boosting', 'Servicio por rango', 15)
)
insert into public.services (category, game, name, description, price)
select s.category, s.game, s.name, s.description, s.price
from source s
where not exists (
  select 1
  from public.services sv
  where coalesce(sv.category, '') = coalesce(s.category, '')
    and coalesce(sv.game, '') = coalesce(s.game, '')
    and sv.name = s.name
);

commit;

-- Verificación rápida (debe devolver datos > 0)
select 'settings' as table_name, count(*) as total from public.settings
union all select 'gold_categories', count(*) from public.gold_categories
union all select 'game_servers', count(*) from public.game_servers
union all select 'gold', count(*) from public.gold
union all select 'services', count(*) from public.services
union all select 'accounts', count(*) from public.accounts
union all select 'customer_references', count(*) from public.customer_references
order by table_name;
