# GUÍA RÁPIDA (SIN ENREDO): crear tu base en Neon

Si estás perdido, sigue **exactamente** esto.
No necesitas saber base de datos.

---

## Objetivo de hoy
Terminar con esto listo:
- Base creada en Neon ✅
- Variables en Vercel ✅

---

## PASO 1 — Copiar `DATABASE_URL` (2 minutos)
### ¿Qué es `DATABASE_URL`?
Es la "dirección completa" para que tu web se conecte a tu base de datos.
Siempre se ve como un texto largo que empieza con:

`postgresql://...`

### ¿Dónde lo saco?
1. En Neon, entra a tu proyecto.
2. Arriba a la derecha, haz clic en **Connect**.
3. En la ventana, busca **Connection string**.
4. Copia el texto completo que empieza con `postgresql://...`.
5. Eso que copiaste es tu **`DATABASE_URL`**.

> Importante: cópialo completo, sin borrar nada.

---

## Si no te deja avanzar todavía
Haz esto y ya:
1. Mándame una captura de la ventana de **Connect** abierta (donde salen las opciones).
2. Yo te marco exactamente cuál línea copiar.

## PASO 2 — Crear variables en Vercel (2 minutos)
1. Ve a **Vercel → tu proyecto → Settings → Environment Variables**.
2. Crea esta variable:
   - **Name**: `DATABASE_URL`
   - **Value**: (pega lo que copiaste de Neon)
3. Crea esta otra:
   - **Name**: `ADMIN_JWT_SECRET`
   - **Value**: `EGS_admin_2026_super_clave_larga_93XkLmPqT7vNw2Rz`
4. Crea estas 2 (login admin):
   - **Name**: `ADMIN_USER`
   - **Value**: `admin`
   - **Name**: `ADMIN_PASSWORD`
   - **Value**: (tu clave admin, ejemplo: `MiClaveAdmin2026!`)
5. Guarda todo.

---

## PASO 3 — Redeploy (1 minuto)
1. En Vercel, ve a **Deployments**.
2. Abre el último deploy.
3. Pulsa **Redeploy**.

Listo. Con eso ya queda conectada la base a nivel de entorno.

---

## PASO 4 — SQL (solo si aún no lo corriste)
Si **ya corriste SQL y te creó tablas**, SALTA este paso.

Si no lo corriste, en Neon → **SQL Editor** pega y ejecuta:

```sql
create extension if not exists pgcrypto;

create table if not exists settings (
  id uuid primary key default gen_random_uuid(),
  discord text,
  whatsapp text,
  tiktok text,
  email text,
  site text,
  updated_at timestamptz not null default now()
);

create table if not exists gold_categories (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text,
  description text,
  image text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists game_servers (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists gold (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  amount integer not null default 0,
  price numeric(12,2) not null default 0,
  delivery text,
  stock text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists accounts (
  id uuid primary key default gen_random_uuid(),
  type text default 'account',
  category text,
  server text,
  name text not null,
  description text,
  price text,
  image text,
  tags jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists customer_references (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  comment text,
  rating integer check (rating between 1 and 5),
  image text,
  created_at timestamptz not null default now()
);

create table if not exists services (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  game text,
  server text,
  name text not null,
  description text,
  price text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

## Qué haces tú y qué hago yo
### Tú
- Solo PASO 1, PASO 2 y PASO 3.

### Yo
- Ya te implementé API + conexión base; después validamos pruebas contigo en producción.

---

## Mensaje que me envías cuando termines
Escríbeme solo esto: **"listo"**.


## Endpoints que ya te dejé creados en el repo
- `GET /api/ping` (diagnóstico rápido)
- `GET /api/catalog`
- `POST /api/admin/login`
- `POST /api/admin/gold`
- `PUT /api/admin/gold`
- `DELETE /api/admin/gold?id=<ID>`
- `POST /api/admin/services`
- `PUT /api/admin/services`
- `DELETE /api/admin/services?id=<ID>`


## Si `https://tu-dominio.com/api/catalog` da 404
Eso significa que el deploy activo no tiene la carpeta `api/` publicada todavía.

Haz esto en orden:
1. En Vercel, abre tu proyecto y entra a **Deployments**.
2. Verifica que el último deploy sea de la rama donde están estos archivos:
   - `api/catalog.js`
   - `api/admin/login.js`
   - `api/admin/gold.js`
   - `api/admin/services.js`
3. Pulsa **Redeploy** del deploy más reciente.
4. Espera que diga **Ready**.
5. Prueba primero con el dominio de Vercel (ejemplo):
   - `https://TU-PROYECTO.vercel.app/api/catalog`
6. Si ahí funciona pero en tu dominio custom no, revisa el dominio en:
   - **Vercel → Settings → Domains**
   - confirma que `www.epicgoldshop.com` apunte al mismo proyecto.

### Resultado esperado
- Si todo está bien, `/api/catalog` debe responder JSON.
- Si responde 500 (no 404), ya encontró el endpoint y solo falta revisar variables de entorno o DB.


## Si `/api/catalog` sigue en 404 (checklist real)
Haz esto exacto:

1. Prueba primero este endpoint de diagnóstico:
   - `https://TU-DEPLOY.vercel.app/api/ping`
2. Si `/api/ping` también da 404, el problema NO es Neon: es configuración/deploy de Vercel.
3. En **Vercel → Project Settings → General** revisa:
   - **Root Directory**: debe apuntar a la carpeta donde está `api/` (en este repo es la raíz).
   - **Production Branch**: debe ser la rama donde subiste estos archivos.
4. En **Deployments**, abre el último deploy y confirma que incluya `api/ping.js` y `api/catalog.js`.
5. Haz **Redeploy** de ese deploy y espera `Ready`.

### Cómo interpretar
- `/api/ping` = 200 y `/api/catalog` = 500 → ya existe API, falta variable/env o DB.
- `/api/ping` = 404 → Vercel no está desplegando esta carpeta/rama.


## Si aún da 404 después de redeploy
Ya dejé un `vercel.json` en el repo para forzar que Vercel publique `/api/*` como funciones Node.

Qué hacer:
1. Sube este último commit a tu repo conectado a Vercel.
2. En Vercel, haz **Redeploy**.
3. Prueba: `https://TU-DEPLOY.vercel.app/api/ping`

Si eso responde JSON, ya quedó arreglado el enrutamiento de API.


## OJO: no uses una URL de deploy vieja
Las URLs como `https://pagina-de-ventas-XXXX.vercel.app` son **inmutables** (quedan pegadas a un build viejo).
Si sigues abriendo la misma URL vieja, siempre verás el mismo 404 aunque ya hayas hecho nuevos deploys.

Usa una de estas dos:
1. El botón **Visit** del deploy más reciente en Vercel.
2. Tu dominio de producción (o alias actual) que apunte al último deploy.

Después prueba otra vez:
- `/api/ping`
- `/api/catalog`


## PLAN B DEFINITIVO (si TODO sigue en 404)
Si ya hiciste todo y `/api/ping` sigue 404, haz esto (soluciona casi siempre):

1. En Vercel, crea **un proyecto nuevo** (Import Project) desde este mismo repo.
2. En la configuración de importación:
   - **Framework Preset**: Other
   - **Root Directory**: `./` (raíz del repo)
   - **Build Command**: vacío
   - **Output Directory**: vacío
3. Agrega variables de entorno en el proyecto nuevo:
   - `DATABASE_URL`
   - `ADMIN_JWT_SECRET`
   - `ADMIN_USER`
   - `ADMIN_PASSWORD`
4. Deploy.
5. Prueba primero en el dominio del nuevo proyecto:
   - `/api/ping`
   - `/api/catalog`
6. Si ahí funciona, mueve tu dominio `www.epicgoldshop.com` a este proyecto nuevo.

### ¿Por qué funciona?
Porque evita configuraciones viejas del proyecto anterior (root/output/branch) que dejan la API fuera del build.


## Si en GitHub no ves los commits de API
Si en GitHub solo ves commits viejos (por ejemplo, solo docs) y no ves `api/`, entonces Vercel nunca podrá desplegar esos endpoints.

Haz esto:
1. Abre la rama correcta en GitHub (la misma donde trabajas aquí).
2. Confirma que existan estos archivos en esa rama:
   - `api/ping.js`
   - `api/catalog.js`
   - `api/admin/login.js`
   - `api/admin/gold.js`
   - `api/admin/services.js`
   - `vercel.json`
3. Si no aparecen, sube la rama con push y luego redeploy en Vercel.
4. En Vercel, en **Settings → Git**, confirma que el proyecto despliega esa misma rama.

Sin esos archivos en GitHub, siempre verás 404 en `/api/*`.


## Deploy nuevo guiado
Si en GitHub no aparecen los archivos API, sigue `DEPLOY_NUEVO_GITHUB.md` paso a paso.

---

## Si la base está vacía (solución rápida)

Ejecuta estos comandos en tu máquina/local:

```bash
export DATABASE_URL='postgresql://USER:PASS@HOST/DB?sslmode=require'
./scripts/seed_neon_from_catalog.sh
```

Esto carga automáticamente `data/catalog.json` en Neon.
Luego prueba:

- `GET /api/catalog`

---

## Importar TODO desde tu archivo de precios (rápido)

Si ya tienes un archivo con precios/productos, no tienes que cargar fila por fila.

1. Crea `data/catalog.json` (puedes copiar `data/catalog.template.json` y reemplazar con tus datos).
2. En tu terminal, ejecuta:

```bash
DATABASE_URL='postgresql://...'
npm run import:catalog
```

> Si ya tienes `DATABASE_URL` exportada en el entorno, solo corre `npm run import:catalog`.

### Formato soportado del JSON

- `settings` (objeto)
- `gold_categories` (array)
- `game_servers` (array)
- `gold` (array)
- `accounts` (array)
- `customer_references` (array)
- `services` (array)

También acepta alias:
- `goldCategories` en vez de `gold_categories`
- `gameServers` en vez de `game_servers`
- `references` en vez de `customer_references`

### Resultado

Al terminar, podrás verificar en:

- `GET /api/catalog`

Si quieres no borrar datos previos, puedes ejecutar el importador con:

```bash
node scripts/import_catalog_to_neon.js data/catalog.json --no-reset
```
