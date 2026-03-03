# Supabase SIN backend (guardado real desde tu página)

Perfecto: sin backend, pero **sí guardando en Supabase** desde el admin de la web.

## 1) Ejecuta el SQL una vez
En Supabase > SQL Editor:
- pega y ejecuta `supabase/setup.sql`


## Configuración aplicada con tus datos
- Project URL: `https://meeloixabjkrniwocrzp.supabase.co`
- Anon Key (Legacy): configurada en `index.html`.

## 2) Configura tu frontend (importante)
En `index.html`, antes del script principal, define:

```html
<script>
  window.SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
  window.SUPABASE_ANON_KEY = 'TU_ANON_KEY';
</script>
```

> Con eso la página se conecta directo a Supabase (sin backend).

## 3) Qué ya hace esta versión
- Lee datos desde Supabase al cargar la web.
- Si editas desde admin, se sincroniza a Supabase.
- Si Supabase falla, usa fallback local para no romper la página.

## 4) Prueba rápida (la que te interesa)
1. Abre admin y agrega/edita 1 paquete de oro o cuenta.
2. Espera 1-2 segundos.
3. Abre la web en incógnito/u otro dispositivo.
4. Si ves el cambio, quedó guardando global para todos.

## 5) Verificación directa en Supabase
Ejecuta:

```sql
select count(*) as cuentas from public.accounts;
select count(*) as paquetes_oro from public.gold;
select count(*) as referencias from public.references;
select * from public.settings limit 1;
```

Si suben/actualizan después de editar en admin, ya está funcionando bien.

## Nota de seguridad
Esta configuración permite escritura con `anon` para usar admin sin backend.
Más adelante, cuando quieras endurecer seguridad, migramos a auth real (sin perder datos).
