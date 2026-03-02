# Checklist rápido: error "revisa RLS y anon key"

Si aparece ese error, normalmente es una de estas 3 causas:

1. Estás usando `sb_secret_...` en frontend (incorrecto).
2. Falta policy `SELECT` para rol `anon`.
3. URL o key no corresponden al mismo proyecto.

## 1) Qué key usar
En frontend (`supabase-config.js`) usa **solo**:
- `sb_publishable_...` (nueva) o
- `anon` JWT antigua (`eyJ...`)

Nunca uses `sb_secret_...` en navegador.

## 2) Verificar URL + key
- URL debe ser: `https://<project-ref>.supabase.co`
- Key y URL deben ser del mismo proyecto Supabase.

## 3) Activar RLS + policies de lectura
Ejecuta esto en SQL Editor (ajusta tablas si cambian):

```sql
alter table public.accounts enable row level security;
alter table public.gold enable row level security;
alter table public.gold_categories enable row level security;
alter table public.game_servers enable row level security;
alter table public.references enable row level security;
alter table public.settings enable row level security;

create policy "accounts_select_anon" on public.accounts
for select to anon using (true);

create policy "gold_select_anon" on public.gold
for select to anon using (true);

create policy "gold_categories_select_anon" on public.gold_categories
for select to anon using (true);

create policy "game_servers_select_anon" on public.game_servers
for select to anon using (true);

create policy "references_select_anon" on public.references
for select to anon using (true);

create policy "settings_select_anon" on public.settings
for select to anon using (true);
```

## 4) Probar una tabla desde navegador
Con tu URL/key publica:

`GET https://<project-ref>.supabase.co/rest/v1/accounts?select=*&limit=1`

Headers:
- `apikey: <publishable>`
- `Authorization: Bearer <publishable>`

Si devuelve 200/json, conexión OK.
