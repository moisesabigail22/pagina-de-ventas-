# Instrucciones Supabase (desde cero, simple)

Esto te deja una base central para tu página de venta de oro, para que cualquier persona que entre vea los mismos datos.

## 1) Crear y ejecutar la base
1. Crea proyecto en Supabase.
2. Ve a **SQL Editor**.
3. Copia y ejecuta completo:
   - `supabase/setup.sql`

## 2) Verificar que quedó bien
Ejecuta estas queries en SQL Editor:

```sql
select count(*) as cuentas from public.accounts;
select count(*) as paquetes_oro from public.gold;
select count(*) as referencias from public.references;
select * from public.settings limit 1;
```

Si todo responde, la base está lista.

## 3) Variables en Vercel
En tu proyecto agrega:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (solo backend)
- `ADMIN_JWT_SECRET`

> Nunca expongas `SUPABASE_SERVICE_ROLE_KEY` en frontend.

## 4) Prueba global (lo importante)
1. Agrega o edita un paquete de oro/cuenta desde tu admin.
2. Abre tu web en otro navegador/dispositivo en modo incógnito.
3. Todos deben ver el mismo dato actualizado.

Si esto se cumple, ya está centralizado para todo el mundo.

## 5) Nota técnica
Tu `index.html` actual guarda en `localStorage`. Para que Supabase sea la fuente real global, el siguiente paso es conectar lectura/escritura a Supabase (por API o directamente con cliente anon para lectura).
