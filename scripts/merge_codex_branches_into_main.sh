#!/usr/bin/env bash
set -euo pipefail

# Mergea ramas remotas codex/* dentro de main de forma segura.
# - Solo borra ramas que YA estén confirmadas dentro de origin/main.
# - Puede hacer limpieza de ramas ya mergeadas antes/después de integrar.
#
# Uso:
#   bash scripts/merge_codex_branches_into_main.sh
# Variables opcionales:
#   REMOTE=origin
#   MAIN_BRANCH=main
#   PREFIX=codex/
#   PUSH_EACH=true|false
#   DELETE_MERGED=false|true
#   KEEP_CURRENT_REMOTE_BRANCH=true|false

REMOTE="${REMOTE:-origin}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
PREFIX="${PREFIX:-codex/}"
PUSH_EACH="${PUSH_EACH:-true}"
DELETE_MERGED="${DELETE_MERGED:-false}"
KEEP_CURRENT_REMOTE_BRANCH="${KEEP_CURRENT_REMOTE_BRANCH:-true}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Este script debe ejecutarse dentro de un repositorio git."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Tu working tree no está limpio. Haz commit/stash antes de ejecutar este script."
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
CURRENT_REMOTE_CANDIDATE="${PREFIX}${CURRENT_BRANCH#${PREFIX}}"

cleanup() {
  git checkout "$CURRENT_BRANCH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "===> Fetch de ramas remotas"
git fetch "$REMOTE" --prune

echo "===> Cambiando a $MAIN_BRANCH"
git checkout "$MAIN_BRANCH"
git pull --ff-only "$REMOTE" "$MAIN_BRANCH"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_BRANCH="backup/${MAIN_BRANCH}-before-merge-${TIMESTAMP}"
git branch "$BACKUP_BRANCH"
echo "✅ Backup creado: $BACKUP_BRANCH"

mapfile -t REMOTE_BRANCHES < <(git for-each-ref --format='%(refname:short)' "refs/remotes/${REMOTE}/${PREFIX}*")

if [ "${#REMOTE_BRANCHES[@]}" -eq 0 ]; then
  echo "⚠️ No se encontraron ramas ${REMOTE}/${PREFIX}*"
  exit 0
fi

echo "===> Ramas detectadas (${#REMOTE_BRANCHES[@]}):"
printf ' - %s\n' "${REMOTE_BRANCHES[@]}"

MERGED_NOW=()
ALREADY_IN_MAIN=()
CONFLICTS=()
DELETED=()
SKIPPED_DELETE=()

is_merged_in_main() {
  local remote_branch="$1"
  git merge-base --is-ancestor "$remote_branch" "${REMOTE}/${MAIN_BRANCH}"
}

safe_delete_remote_branch() {
  local branch="$1"

  if [ "$DELETE_MERGED" != "true" ]; then
    return 0
  fi

  if [ "$KEEP_CURRENT_REMOTE_BRANCH" = "true" ] && [ "$branch" = "$CURRENT_REMOTE_CANDIDATE" ]; then
    SKIPPED_DELETE+=("$branch (rama actual protegida)")
    return 0
  fi

  if is_merged_in_main "${REMOTE}/${branch}"; then
    if git push "$REMOTE" --delete "$branch"; then
      DELETED+=("$branch")
    else
      SKIPPED_DELETE+=("$branch (falló delete remoto)")
    fi
  else
    SKIPPED_DELETE+=("$branch (no está en ${REMOTE}/${MAIN_BRANCH})")
  fi
}

for remote_branch in "${REMOTE_BRANCHES[@]}"; do
  local_branch="${remote_branch#${REMOTE}/}"

  if [ "$local_branch" = "$MAIN_BRANCH" ]; then
    continue
  fi

  echo ""
  echo "===> Procesando: $remote_branch"

  if is_merged_in_main "$remote_branch"; then
    echo "✅ Ya estaba mergeada en ${REMOTE}/${MAIN_BRANCH}: $local_branch"
    ALREADY_IN_MAIN+=("$local_branch")
    safe_delete_remote_branch "$local_branch"
    continue
  fi

  if git merge --no-ff --no-edit "$remote_branch"; then
    MERGED_NOW+=("$local_branch")
    echo "✅ Merge OK: $local_branch"

    if [ "$PUSH_EACH" = "true" ]; then
      git push "$REMOTE" "$MAIN_BRANCH"
      git fetch "$REMOTE" --prune
      echo "⬆️ Push realizado"
      safe_delete_remote_branch "$local_branch"
    fi
  else
    echo "❌ Conflicto en: $local_branch"
    CONFLICTS+=("$local_branch")
    git merge --abort || true
  fi
done

if [ "$PUSH_EACH" != "true" ] && [ "${#MERGED_NOW[@]}" -gt 0 ]; then
  git push "$REMOTE" "$MAIN_BRANCH"
  git fetch "$REMOTE" --prune
  echo "⬆️ Push final realizado"

  for b in "${MERGED_NOW[@]}"; do
    safe_delete_remote_branch "$b"
  done
fi

echo ""
echo "================ RESUMEN ================"
echo "✅ Integradas en esta ejecución: ${#MERGED_NOW[@]}"
for b in "${MERGED_NOW[@]:-}"; do
  [ -n "$b" ] && echo "   - $b"
done

echo "✅ Ya estaban en main: ${#ALREADY_IN_MAIN[@]}"
for b in "${ALREADY_IN_MAIN[@]:-}"; do
  [ -n "$b" ] && echo "   - $b"
done

echo "❌ Con conflicto: ${#CONFLICTS[@]}"
for b in "${CONFLICTS[@]:-}"; do
  [ -n "$b" ] && echo "   - $b"
done

echo "🗑️ Borradas remotas: ${#DELETED[@]}"
for b in "${DELETED[@]:-}"; do
  [ -n "$b" ] && echo "   - $b"
done

echo "⏭️ No borradas: ${#SKIPPED_DELETE[@]}"
for b in "${SKIPPED_DELETE[@]:-}"; do
  [ -n "$b" ] && echo "   - $b"
done

echo "📌 Backup branch: $BACKUP_BRANCH"
