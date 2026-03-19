-- Genera paquetes de oro automáticamente a partir del precio base de 100.
-- Compatible con bases donde public.gold.amount puede ser integer o text.
-- Requisito: cada juego/servidor debe tener al menos un registro con amount = 100 en public.gold.
-- Montos generados: 100, 200, 300, 400, 500, 1000, 5000, 10000.
-- Fórmula: price = price_100 * (amount / 100).

begin;

with desired_amounts(amount_text, amount_numeric) as (
  values
    ('100', 100),
    ('200', 200),
    ('300', 300),
    ('400', 400),
    ('500', 500),
    ('1000', 1000),
    ('5000', 5000),
    ('10000', 10000)
),
base_prices as (
  select
    g.game,
    g.server,
    round(g.price::numeric, 2) as price_100
  from public.gold g
  where trim(g.amount::text) = '100'
),
generated as (
  select
    b.game,
    b.server,
    a.amount_text,
    round((b.price_100 * a.amount_numeric / 100.0)::numeric, 2) as price
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
  and trim(g.amount::text) = src.amount_text;

with desired_amounts(amount_text, amount_numeric) as (
  values
    ('100', 100),
    ('200', 200),
    ('300', 300),
    ('400', 400),
    ('500', 500),
    ('1000', 1000),
    ('5000', 5000),
    ('10000', 10000)
),
base_prices as (
  select
    g.game,
    g.server,
    round(g.price::numeric, 2) as price_100
  from public.gold g
  where trim(g.amount::text) = '100'
),
generated as (
  select
    b.game,
    b.server,
    a.amount_text,
    round((b.price_100 * a.amount_numeric / 100.0)::numeric, 2) as price
  from base_prices b
  cross join desired_amounts a
)
insert into public.gold (game, server, amount, price)
select src.game, src.server, src.amount_text, src.price
from generated src
where not exists (
  select 1
  from public.gold g
  where g.game = src.game
    and g.server = src.server
    and trim(g.amount::text) = src.amount_text
);

commit;

-- Verificación rápida
select game, server, amount, price
from public.gold
where trim(amount::text) in ('100', '200', '300', '400', '500', '1000', '5000', '10000')
order by game, server, amount::text;
