# Base de datos MÁS fácil (1 tabla)

Si lo otro te complicó, esta es la versión simple de verdad.

## Cómo funciona
- Solo usamos **1 tabla** en Supabase: `app_state`.
- Ahí se guarda todo junto (cuentas, oro, referencias, settings, etc.) en JSON.
- Tu admin sigue igual, pero ahora sincroniza ese JSON a Supabase.

## Paso 1: ejecutar SQL
En Supabase > SQL Editor ejecuta:
- `supabase/setup.sql`

## Paso 2: poner tus claves en `index.html`
Ya quedaron puestas en este proyecto:
- `window.SUPABASE_URL = 'https://meeloixabjkrniwocrzp.supabase.co'`
- `window.SUPABASE_ANON_KEY = '...'`

## Paso 3: probar guardado global
1. En admin cambia algo (cuenta, oro, referencia, etc.).
2. Espera 1-2 segundos.
3. Abre la web en incógnito/u otro dispositivo.
4. Debe verse igual.

## Verificación en Supabase
```sql
select id, updated_at from public.app_state;
select jsonb_pretty(data) from public.app_state where id = 'main';
```

Si `updated_at` cambia cuando editas en admin, ya está guardando bien.
