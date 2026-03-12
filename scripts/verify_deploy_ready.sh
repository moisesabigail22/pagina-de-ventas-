#!/usr/bin/env bash
set -euo pipefail

required=(
  "api/ping.js"
  "api/catalog.js"
  "api/admin/login.js"
  "api/admin/gold.js"
  "api/admin/gold-categories.js"
  "api/admin/game-servers.js"
  "api/admin/services.js"
  "api/_lib/db.js"
  "api/_lib/auth.js"
  "package.json"
  "vercel.json"
)

missing=0
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    missing=1
  else
    echo "OK: $f"
  fi
done

if [[ $missing -ne 0 ]]; then
  echo "\n❌ Faltan archivos para el deploy."
  exit 1
fi

echo "\n✅ Todo listo para deploy."
