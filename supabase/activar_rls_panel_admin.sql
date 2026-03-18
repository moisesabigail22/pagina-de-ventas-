-- Ejecuta este fix en Supabase SQL Editor para permitir que el panel admin actual
-- guarde datos usando la anon key del frontend.
-- OJO: esto habilita escritura desde anon en las tablas del panel.


-- Escritura desde el panel actual (cliente con anon key)
drop policy if exists "anon manage settings" on public.settings;
create policy "anon manage settings" on public.settings
for all to anon using (true) with check (true);

drop policy if exists "anon manage gold_categories" on public.gold_categories;
create policy "anon manage gold_categories" on public.gold_categories
for all to anon using (true) with check (true);

drop policy if exists "anon manage game_servers" on public.game_servers;
create policy "anon manage game_servers" on public.game_servers
for all to anon using (true) with check (true);

drop policy if exists "anon manage gold" on public.gold;
create policy "anon manage gold" on public.gold
for all to anon using (true) with check (true);

drop policy if exists "anon manage accounts" on public.accounts;
create policy "anon manage accounts" on public.accounts
for all to anon using (true) with check (true);

drop policy if exists "anon manage services" on public.services;
create policy "anon manage services" on public.services
for all to anon using (true) with check (true);

drop policy if exists "anon manage customer_references" on public.customer_references;
create policy "anon manage customer_references" on public.customer_references
for all to anon using (true) with check (true);
