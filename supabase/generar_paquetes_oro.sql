-- Genera paquetes de oro automáticamente a partir del precio base de 100.
-- Requisito: cada juego/servidor debe tener al menos un registro con amount = 100 en public.gold.
-- Montos generados: 100, 200, 300, 400, 500, 1000, 5000, 10000.
-- Fórmula: price = price_100 * (amount / 100).

begin;

with desired_amounts(amount) as (
  values (100), (200), (300), (400), (500), (1000), (5000), (10000)
),
base_prices as (
  select
    g.game,
    g.server,
    round(g.price::numeric, 2) as price_100
  from public.gold g
  where g.amount = 100
),
generated as (
  select
    b.game,
    b.server,
    a.amount,
    round((b.price_100 * a.amount / 100.0)::numeric, 2) as price
  from base_prices b
  cross join desired_amounts a
)
update public.gold g
set
  price = src.price,
  updated_at = now()
from generated src
where g.game = src.game
  and g.server = src.server
  and g.amount = src.amount;

with desired_amounts(amount) as (
  values (100), (200), (300), (400), (500), (1000), (5000), (10000)
),
base_prices as (
  select
    g.game,
    g.server,
    round(g.price::numeric, 2) as price_100
  from public.gold g
  where g.amount = 100
),
generated as (
  select
    b.game,
    b.server,
    a.amount,
    round((b.price_100 * a.amount / 100.0)::numeric, 2) as price
  from base_prices b
  cross join desired_amounts a
)
insert into public.gold (game, server, amount, price)
select src.game, src.server, src.amount, src.price
from generated src
where not exists (
  select 1
  from public.gold g
  where g.game = src.game
    and g.server = src.server
    and g.amount = src.amount
);

commit;

-- Verificación rápida
select game, server, amount, price
from public.gold
where amount in (100, 200, 300, 400, 500, 1000, 5000, 10000)
order by game, server, amount;
