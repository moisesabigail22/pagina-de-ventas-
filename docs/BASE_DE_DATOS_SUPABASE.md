# Guía desde cero: Base de datos para Epic Gold Shop (Supabase + Vercel)

Esta guía te deja la base lista para que tu panel admin guarde cambios en una base de datos real y todos los usuarios vean lo mismo en cualquier dispositivo.

## 0) Qué problema resuelve
Actualmente la web usa `localStorage` (datos locales por navegador). Eso significa:
- Tus cambios no se comparten automáticamente a otros usuarios.
- Cada teléfono/PC puede ver datos distintos.

Con Supabase:
- Los datos viven en una DB central (PostgreSQL).
- Cualquier deploy reciente lee la misma información.
- Lo que editas en admin se refleja para todos.

---

## 1) Crear proyecto en Supabase
1. Entra a https://supabase.com
2. Crea cuenta / inicia sesión.
3. Clic en **New project**.
4. Completa:
   - Organization
   - Project name (ej: `epicgoldshop`)
   - Database password (guárdala)
   - Region (cerca de tu público)
5. Espera que termine el provisioning.

---

## 2) Crear tablas (schema)
1. Abre tu proyecto en Supabase.
2. Ve a **SQL Editor**.
3. Crea una consulta nueva.
4. Copia y ejecuta el contenido de `supabase/schema.sql` de este repo.

Eso crea tablas para:
- `accounts`
- `gold`
- `gold_categories`
- `game_servers`
- `references`
- `settings`

---

## 3) Configurar seguridad (RLS) de forma simple
Para iniciar rápido:
- Mantén lectura pública solo para catálogo (accounts/gold/categories/servers/references/settings)
- Escritura solo con credenciales admin (service role en backend)

> Importante: **nunca** pongas `service_role` key en frontend público.

---

## 4) Obtener variables de entorno
En Supabase > **Project Settings** > **API** copia:
- `Project URL`
- `anon public key`
- (service_role solo para backend)

---

## 5) Configurar en Vercel
En Vercel > tu proyecto > **Settings** > **Environment Variables** añade:
- `SUPABASE_URL` = tu Project URL
- `SUPABASE_ANON_KEY` = tu anon key
- `SUPABASE_SERVICE_ROLE_KEY` = service role key (solo server-side)

Luego redeploy.

---

## 6) Estrategia de integración (la que te voy a implementar)
### Fase A (lectura global)
- Reemplazar `loadData()` para leer desde Supabase.
- Si hay error de red, usar fallback temporal local.

### Fase B (panel admin escribiendo en DB)
- Crear endpoints serverless (`/api/...`) en Vercel.
- Altas/ediciones/borrados del admin guardan en DB central.

### Fase C (auth real admin)
- Login admin contra backend (no hardcodeado en frontend).
- Auditoría básica (fecha de cambios, usuario).

---

## 7) Checklist de éxito
- [ ] Desde PC A agregas una categoría/juego.
- [ ] Abres link en teléfono o PC B.
- [ ] Se ve exactamente lo mismo sin borrar caché.
- [ ] Eliminas un ítem en admin.
- [ ] Desaparece para todos los usuarios.

---

## 8) Costos/recomendación
- Supabase free tier sirve para empezar.
- Cuando crezca el tráfico, subir plan.
- Para imágenes de usuarios, usar bucket Storage (Supabase o Cloudinary).

---

## 9) Siguiente paso
Con esto listo, yo me encargo de:
1) conectar frontend a lectura DB,
2) crear APIs de escritura del panel admin,
3) dejar autenticación admin segura.
