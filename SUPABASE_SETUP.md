# Base de datos completa en Supabase (con nombres por sección)

Entendido: quieres **la base completa** (no una sola tabla), y que al guardar desde la página se persista en Supabase.

Este proyecto ahora usa estas tablas:
- `accounts`
- `gold_packages`
- `gold_categories`
- `references`
- `site_settings`
- `categories`
- `game_servers`

Cada fila guarda el objeto original en `data jsonb`, así no pierdes campos de tu frontend.

## Paso 1) Crear proyecto Supabase

1. Entra a [supabase.com](https://supabase.com).
2. Crea tu proyecto.
3. En **Project Settings > API** copia:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

## Paso 2) Crear la base (todas las tablas)

📍 Dónde: **Supabase Dashboard > SQL Editor**

1. Abre `supabase/schema.sql` en tu repo.
2. Copia/pega todo en SQL Editor.
3. Ejecuta.

Ese SQL crea tablas, triggers `updated_at` y policies RLS para poder leer/escribir rápido desde la página.

## Paso 3) Vincular la página

📍 Dónde: `index.html`

Ya quedó configurado con tu proyecto:

```js
const SUPABASE_URL = "https://syhpmjsmnveflltqgakb.supabase.co";
const SUPABASE_ANON_KEY = "<anon-key>";
```

> Nunca uses `service_role` ni `secret key` en frontend.

Configuración compatible con ambos deploys:

```js
const SUPABASE_URL = resolveSupabaseValue(['__SUPABASE_URL__', 'SUPABASE_URL'], '<url>');
const SUPABASE_ANON_KEY = resolveSupabaseValue(['__SUPABASE_ANON_KEY__', 'SUPABASE_ANON_KEY', 'SUPABASE_PUBLISHABLE_KEY'], '<anon>');
```

- Deploy nuevo: usa `window.__SUPABASE_URL__` y `window.__SUPABASE_ANON_KEY__`.
- Deploy anterior: usa `window.SUPABASE_URL` y `window.SUPABASE_ANON_KEY`.
- También soporta `window.__ENV__.*` si inyectas variables por script.

## Paso 4) Cómo guarda ahora

- Al cargar la página, intenta leer desde Supabase (`accounts`, `gold_packages`, etc.).
- Si Supabase está vacío, sube el estado actual inicial de la página.
- Cuando haces cambios en la página (que ya disparan `localStorage.setItem('epicgoldshop_*', ...)`) también se sincroniza Supabase automáticamente.
- Al salir de la página (`beforeunload`) también fuerza una sincronización.

## Importante

Esta configuración es para arrancar rápido. Luego, para producción:
- limita RLS por usuario admin,
- y mueve escrituras a backend seguro.


## Seguridad inmediata recomendada

Como compartiste keys sensibles en el chat, te recomiendo rotarlas en Supabase:
1. Project Settings > API > Rotate keys.
2. Actualiza en `index.html` solo la nueva `anon`/`publishable` key.
3. No expongas `service_role` en cliente ni repositorio.


## Nota sobre eliminaciones

Ahora, cuando una tabla remota queda vacía, la página también la refleja vacía al recargar (ya no conserva datos locales viejos para esa sección).


## Vercel (producción) - branch y variables

Para que producción use estas actualizaciones:

1. En Vercel > Project > Settings > Git, valida **Production Branch** (ej. `main`).
2. Asegúrate de mergear este branch a ese branch de producción.
3. En Vercel > Settings > Environment Variables define (si usas runtime vars):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. Si tu deploy usa inyección en `window.__SUPABASE_*` o `window.__ENV__.*`, también es compatible.

Adicionalmente, la página ahora hace refresh remoto periódico (30s) y al volver foco para reflejar cambios hechos directo en la base (por ejemplo borrados). 


## Verificar que producción ya tiene este deploy

1. Haz deploy en el **Production Branch** de Vercel.
2. Verifica con:

```bash
curl -sL https://epicgoldshop.com/ | rg "SUPABASE_SYNC_VERSION"
```

Si devuelve `SUPABASE_SYNC_VERSION: 2026-02-26-2`, ya estás en el deploy correcto.

3. Verifica datos en vivo:

```bash
curl -sL https://epicgoldshop.com/ | rg "supabase-js"
```

Además, este repo ahora incluye `vercel.json` con `Cache-Control: no-store` para evitar que producción quede pegada a HTML viejo.


## Realtime recomendado (para que producción refleje cambios inmediatos)

La página ya quedó con suscripción Realtime a cambios en tablas (`accounts`, `gold_packages`, etc.) y fallback polling.

En Supabase valida:
1. Database > Replication: habilita tablas públicas usadas.
2. Realtime esté activo para `postgres_changes`.

Si Realtime está activo, al borrar/editar en DB se refleja casi al instante en la página abierta.


## Evitar que producción “vuelva” a versión demo al refrescar

El cliente ahora, cuando detecta Supabase activo, **no usa datos de ejemplo** como fallback si no hay `localStorage`.
Así evita mostrar versión vieja/demo mientras carga datos reales desde la DB.
