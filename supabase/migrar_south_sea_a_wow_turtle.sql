-- Migra South Sea desde servidores privados hacia WoW Turtle.
-- Ejecutar una sola vez en Supabase SQL Editor.

begin;

-- GAME SERVERS: elimina duplicados conflictivos y mueve South Sea a WoW Turtle.
delete from public.game_servers wrong
using public.game_servers correct
where wrong.name = 'South Sea'
  and wrong.game <> 'WoW Turtle'
  and correct.name = 'South Sea'
  and correct.game = 'WoW Turtle';

update public.game_servers
set game = 'WoW Turtle'
where name = 'South Sea'
  and game <> 'WoW Turtle';

insert into public.game_servers (game, name)
select 'WoW Turtle', 'South Sea'
where not exists (
  select 1
  from public.game_servers gs
  where gs.game = 'WoW Turtle'
    and gs.name = 'South Sea'
);

-- GOLD PACKAGES: elimina duplicados conflictivos y mueve los paquetes de South Sea a WoW Turtle.
delete from public.gold wrong
using public.gold correct
where wrong.server = 'South Sea'
  and wrong.game <> 'WoW Turtle'
  and correct.server = 'South Sea'
  and correct.game = 'WoW Turtle'
  and correct.amount::text = wrong.amount::text;

update public.gold
set
  game = 'WoW Turtle',
  updated_at = now()
where server = 'South Sea'
  and game <> 'WoW Turtle';

commit;

-- Verificación rápida
select 'game_servers' as table_name, game, name, null::text as amount, null::text as price
from public.game_servers
where name = 'South Sea'
union all
select 'gold' as table_name, game, server as name, amount::text, price::text
from public.gold
where server = 'South Sea'
order by table_name, amount nulls first;
