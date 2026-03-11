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
- Si vienes de tabla vieja `references`, el schema la migra a `customer_references`.
