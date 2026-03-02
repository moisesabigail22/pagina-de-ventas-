# Deploy Supabase + Vercel (sin backend propio)

## 1) Configuración frontend (este repo)
Edita `supabase-config.js`:
- `url`: tu **Project URL** de Supabase.
- `anonKey`: tu **Publishable key** (ya cargada en este repo).

## 2) Clave secreta (NO va al frontend)
La key `sb_secret__...` **no se debe poner en `index.html` ni en `supabase-config.js`**.

Guárdala solo en Vercel:
- Project → Settings → Environment Variables
- Nombre sugerido: `SUPABASE_SECRET_KEY`
- Valor: tu `sb_secret__...`

> Esta key solo debe usarse si más adelante agregas API routes/serverless.

## 3) RLS obligatorio
Para que la publishable key funcione en navegador, activa RLS y crea políticas `SELECT` para tablas públicas:
- `accounts`
- `gold`
- `gold_categories`
- `game_servers`
- `references`
- `settings`

## 4) Deploy
1. Push al repo.
2. Redeploy en Vercel.
3. Abre la web y valida que cargue catálogo desde Supabase.
