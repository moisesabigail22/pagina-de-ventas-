#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "❌ Falta DATABASE_URL en el entorno"
  echo "Ejemplo:"
  echo "  export DATABASE_URL='postgresql://USER:PASS@HOST/DB?sslmode=require'"
  exit 1
fi

echo "🚀 Importando data/catalog.json a Neon..."
node scripts/import_catalog_to_neon.js data/catalog.json

echo "✅ Importación finalizada. Verifica en /api/catalog"
