-- Seed y verificación para anclar catálogo en Supabase
-- Ejecutar DESPUÉS de supabase/schema.sql

begin;

-- SETTINGS (singleton)
insert into public.settings (discord, whatsapp, tiktok, email, site)
values (
  'https://discord.gg/AYJkmeZn',
  'https://wa.me/1234567890',
  'https://www.tiktok.com/@farmers.de.mmorpg',
  'soporte@epicgoldshop.com',
  'https://www.epicgoldshop.com'
)
on conflict ((true)) do update set
  discord = excluded.discord,
  whatsapp = excluded.whatsapp,
  tiktok = excluded.tiktok,
  email = excluded.email,
  site = excluded.site,
  updated_at = now();

-- CATEGORÍAS DE ORO
insert into public.gold_categories (game, server, description, image)
values
  ('WoW Turtle', 'Nordanaar', 'Gold para Turtle WoW en servidores Ambershire, Nordanaar, Telabim y South Sea.', 'https://i.imgur.com/wwQK4J5.jpeg'),
  ('WoW Privado', 'Warmane', 'Gold para servidores privados incluyendo Bronzebeard, Warmane y Project Epoch.', 'https://i.imgur.com/E3a0Q5L.jpeg'),
  ('WoW Oficial', 'Nightslayer A/H', 'Gold para servidor oficial con stock verificado.', 'https://i.imgur.com/5Yh4leB.jpeg')
on conflict (game, server) do update set
  description = excluded.description,
  image = excluded.image,
  updated_at = now();

-- SERVIDORES
insert into public.game_servers (game, name)
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
on conflict (game, name) do nothing;

-- ORO
insert into public.gold (game, server, amount, price, delivery, stock)
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
on conflict (game, server, amount) do update set
  price = excluded.price,
  delivery = excluded.delivery,
  stock = excluded.stock,
  updated_at = now();

-- SERVICIOS
insert into public.services (category, game, name, description, price)
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
on conflict (category, game, name) do update set
  description = excluded.description,
  price = excluded.price,
  updated_at = now();

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
