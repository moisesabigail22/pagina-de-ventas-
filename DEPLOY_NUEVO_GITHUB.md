# Deploy nuevo (GitHub + Vercel) con API activa

Este paso es para cuando en GitHub/Vercel no aparecen los archivos `api/*`.

## 1) Verifica archivos antes de subir
Desde tu repo local, ejecuta:

```bash
./scripts/verify_deploy_ready.sh
```

Debe mostrar `OK` para:
- `api/ping.js`
- `api/catalog.js`
- `api/admin/login.js`
- `api/admin/gold.js`
- `api/_lib/db.js`
- `api/_lib/auth.js`
- `package.json`
- `vercel.json`

---

## 2) Sube la rama que SÍ tiene estos archivos
Ejemplo (si tu rama es `work`):

```bash
git checkout work
git add -A
git commit -m "Deploy-ready: Neon API + Vercel config"
git push origin work
```

Si quieres producción en `main`:

```bash
git checkout main
git pull origin main
git merge work
git push origin main
```

---

## 3) En Vercel, usa esa misma rama
1. `Settings` → `Git`
2. `Production Branch` = la rama que subiste (`work` o `main`)
3. `Deployments` → `Redeploy`

---

## 4) Variables obligatorias en Vercel
- `DATABASE_URL`
- `ADMIN_JWT_SECRET`
- `ADMIN_USER`
- `ADMIN_PASSWORD`

---

## 5) Prueba rápida
- `https://TU-DOMINIO/api/ping`
- `https://TU-DOMINIO/api/catalog`

Si `ping` responde JSON, la API quedó desplegada.
