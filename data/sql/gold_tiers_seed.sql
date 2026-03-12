-- Seed de ORO por tramos (100g, 200g, 300g, 500g, 1000g)
-- 1) Ajusta la tabla base_prices con tu precio por 100g para cada juego/servidor.
-- 2) Ejecuta el script en Neon.

begin;

-- Opcional: limpiar gold para recalcular todo
delete from gold;

with base_prices(game, server, price_100) as (
  values
    ('WoW Turtle', 'Ambershire', 3.50::numeric),
    ('WoW Turtle', 'Nordanaar', 2.50::numeric),
    ('WoW Turtle', 'Telabim', 4.50::numeric),
    ('WoW Turtle', 'South Sea', 3.00::numeric),
    ('WoW Privado', 'Bronzebeard', 3.00::numeric),
    ('WoW Privado', 'Warmane', 2.50::numeric),
    ('WoW Privado', 'Project Epoch - Kezan', 4.00::numeric),
    ('WoW Privado', 'Project Epoch - Gurubashi', 3.00::numeric),
    ('WoW Oficial', 'Nightslayer A/H', 5.80::numeric)
),
tiers(amount) as (
  values (100), (200), (300), (500), (1000)
)
insert into gold (game, server, amount, price, created_at, updated_at)
select
  b.game,
  b.server,
  t.amount,
  round((b.price_100 * t.amount / 100.0)::numeric, 2) as price,
  now(),
  now()
from base_prices b
cross join tiers t
order by b.game, b.server, t.amount;

commit;
