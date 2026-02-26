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
