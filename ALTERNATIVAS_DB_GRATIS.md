# Alternativas gratis a Supabase (para proyectos pequeños)

Si quieres algo **fácil**, con poco código y sin Supabase, estas son buenas opciones:

## 1) Firebase (Firestore)
- Plan gratis generoso para proyectos pequeños.
- SDK muy simple para web.
- Ideal si quieres empezar rápido con frontend.
- Web: https://firebase.google.com/

## 2) Neon (PostgreSQL)
- PostgreSQL serverless con plan gratis.
- Muy bueno si prefieres SQL tradicional.
- Puedes conectarlo desde backend o herramientas no-code.
- Web: https://neon.tech/

## 3) Turso (SQLite distribuido)
- Muy ligero, rápido y simple para apps chicas.
- Plan gratis disponible.
- Excelente cuando el volumen de datos es bajo.
- Web: https://turso.tech/

## 4) Railway (PostgreSQL)
- Muy fácil de desplegar y administrar.
- Suele ofrecer créditos gratis para arrancar.
- Buena UX para empezar sin complicarte.
- Web: https://railway.app/

## 5) MongoDB Atlas (M0)
- Cluster gratis (M0).
- Útil si te acomoda más un modelo documento.
- Integraciones sencillas con Node.js.
- Web: https://www.mongodb.com/atlas

---

## Recomendación rápida para tu caso ("poco código")

- Si quieres **menos fricción en frontend**: usa **Firebase**.
- Si quieres **SQL clásico y crecer después**: usa **Neon + PostgreSQL**.
- Si quieres algo **muy liviano**: usa **Turso**.

## Stack mínimo sugerido (simple)
- Frontend estático (tu `index.html`).
- API pequeña en Vercel/Netlify Functions.
- DB: Neon (Postgres) o Turso.

Así mantienes costos bajos y complejidad mínima.
