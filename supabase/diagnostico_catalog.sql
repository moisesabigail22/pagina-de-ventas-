-- Diagnóstico: "veo datos en la web pero no aparecen en Supabase"
-- Ejecuta en Supabase SQL Editor (proyecto que CREES que está conectado a la web)

-- 1) ¿Existen las tablas esperadas?
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'settings',
    'gold_categories',
    'game_servers',
    'gold',
    'services',
    'accounts',
    'customer_references'
  )
order by table_name;

-- 2) Conteos rápidos
select 'settings' as table_name, count(*) as total from public.settings
union all select 'gold_categories', count(*) from public.gold_categories
union all select 'game_servers', count(*) from public.game_servers
union all select 'gold', count(*) from public.gold
union all select 'services', count(*) from public.services
union all select 'accounts', count(*) from public.accounts
union all select 'customer_references', count(*) from public.customer_references
order by table_name;

-- 3) Muestras para confirmar contenido real
select * from public.settings order by updated_at desc limit 3;
select game, server, amount, price from public.gold order by created_at desc limit 10;
select category, game, name, price from public.services order by created_at desc limit 10;

-- 4) Si sale vacío, luego corre en este orden:
--    a) supabase/schema.sql
--    b) supabase/seed_catalog.sql
--    c) vuelve a ejecutar este diagnóstico
