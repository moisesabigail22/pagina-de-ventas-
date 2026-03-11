# Guía desde cero: Base de datos anclada en Supabase (Epic Gold Shop)

Esta guía deja tu base de datos fija con **oro + servicios + categorías + servidores** y valida que realmente quedó cargada.

## 1) Ejecutar esquema base
En Supabase > **SQL Editor** ejecuta primero:
1. `supabase/schema.sql`
2. `supabase/part3_rls_admin.sql` (opcional si usarás login admin por backend)

## 2) Cargar catálogo (oro y servicios)
Luego ejecuta:
- `supabase/seed_catalog.sql`

Ese script:
- Verifica/crea lo que falta (`services`, `customer_references` y compatibilidad con `references` antigua).
- Inserta o actualiza automáticamente datos de:
  - `settings`
  - `gold_categories`
  - `game_servers`
  - `gold`
  - `services`
- Incluye consulta final de verificación por conteo.

## 3) Verificar que sí quedó anclada la base
Al final del `seed_catalog.sql` verás una tabla con conteos. Debe haber números mayores a 0 en:
- `gold_categories`
- `game_servers`
- `gold`
- `services`
- `settings`

## 4) Variables en Vercel (si usas API backend)
En Vercel > Project > Settings > Environment Variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (solo backend)

Haz redeploy luego de guardar variables.

## 5) Notas importantes
- No uses `service_role` en frontend público.
- `seed_catalog.sql` está hecho para poder re-ejecutarse sin duplicar filas clave (usa lógica `update + insert where not exists`).
- `seed_catalog.sql` detecta si `gold.amount` está en `text` o `integer` y se adapta automáticamente para evitar errores de tipo.
- Si vienes de tabla vieja `references`, el schema la migra a `customer_references`.

## 6) Si en la web hay datos pero en Supabase no aparece nada
Esto casi siempre es una de estas 3 cosas:
1. La web está mostrando datos guardados en `localStorage` del navegador (no DB).
2. Vercel apunta a otro proyecto/variables de Supabase distintas.
3. No se ejecutó seed en el proyecto correcto de Supabase.

Checklist corto:
- Abre tu web en incógnito o en otro teléfono limpio (sin datos locales).
- En Supabase ejecuta `supabase/diagnostico_catalog.sql`.
- Si los conteos salen en 0, ejecuta:
  1) `supabase/schema.sql`
  2) `supabase/seed_catalog.sql`
  3) `supabase/diagnostico_catalog.sql` otra vez
- En Vercel confirma que `SUPABASE_URL` y `SUPABASE_ANON_KEY` pertenecen al mismo proyecto donde corriste SQL.

Nota importante: que estés en branch `main` o `work` NO crea datos por sí solo en Supabase.
Los datos aparecen en Supabase solo cuando corres SQL seed en ese proyecto o cuando el backend escribe correctamente en esa DB.


## 7) Caso puntual: “despausé Supabase y no había datos, pero en la web sí”
Eso casi siempre significa que la web estaba leyendo `localStorage` (datos del navegador) y no la DB central.

Pasos rápidos:
1. Ejecuta `supabase/diagnostico_catalog.sql` en Supabase.
2. Si está vacío, corre `supabase/schema.sql` y luego `supabase/seed_catalog.sql`.
3. Si en la web había datos personalizados, recupéralos con `docs/RECUPERAR_DATOS_LOCALSTORAGE.md`.

