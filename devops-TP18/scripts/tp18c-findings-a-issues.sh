#!/usr/bin/env bash
# TP18C - Sincroniza hallazgos Critical/High ACTIVOS de DefectDojo hacia GitHub Issues.
# Alternativa robusta a la integracion nativa (ver docs/TP18-B-C-D.md, seccion TP18C).
# Con "Auto-add to project" de GitHub Projects v2 los Issues aparecen solos en el tablero.
# Idempotente: no duplica (busca "[DD-<id>]" en el titulo, abiertos o cerrados).
# Env: DEFECTDOJO_URL, DEFECTDOJO_API_KEY, GH_TOKEN, PRODUCT_NAME, GITHUB_REPOSITORY, MAX_ISSUES
set -Eeuo pipefail

: "${DEFECTDOJO_URL:?}"; : "${DEFECTDOJO_API_KEY:?}"; : "${GH_TOKEN:?}"
REPO="${GITHUB_REPOSITORY:-operaciones-unahur/grupo-3}"
PRODUCT_NAME="${PRODUCT_NAME:-Notes App}"
LABELS="${ISSUE_LABELS:-security,defectdojo}"
MAX="${MAX_ISSUES:-10}"      # tope por corrida para no inundar el repo

api() { curl -fsS -H "Authorization: Token $DEFECTDOJO_API_KEY" -G "$@"; }

PID="$(api "$DEFECTDOJO_URL/api/v2/products/" --data-urlencode "name=$PRODUCT_NAME" | jq -r '.results[0].id // empty')"
[ -n "$PID" ] || { echo "Producto '$PRODUCT_NAME' no existe en DefectDojo todavia"; exit 0; }

for l in ${LABELS//,/ }; do gh label create "$l" --repo "$REPO" --force >/dev/null 2>&1 || true; done

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
for sev in Critical High; do
  api "$DEFECTDOJO_URL/api/v2/findings/" \
      --data-urlencode "active=true" --data-urlencode "duplicate=false" \
      --data-urlencode "severity=$sev" --data-urlencode "test__engagement__product=$PID" \
      --data-urlencode "limit=100" \
  | jq -c '.results[] | {id,title,severity,cwe,file_path,line,description}' >> "$tmp"
done

creados=0
while read -r f; do
  [ -n "$f" ] || continue
  id=$(jq -r .id <<<"$f"); sev=$(jq -r .severity <<<"$f"); title=$(jq -r .title <<<"$f")
  tag="[DD-$id]"
  existentes=$(gh issue list --repo "$REPO" --state all --search "\"$tag\" in:title" --json number --jq 'length')
  [ "$existentes" != "0" ] && continue
  [ "$creados" -ge "$MAX" ] && { echo "Tope de $MAX Issues alcanzado."; break; }
  body=$(jq -r '"**Severidad:** \(.severity)\n**CWE:** \(.cwe // "n/a")\n**Ubicacion:** \(.file_path // "n/a"):\(.line // "")\n\n### Descripcion\n\(.description // "")\n\n---\nGenerado desde DefectDojo (finding \(.id)). Cerrar el Issue cuando el hallazgo quede Mitigated."' <<<"$f")
  gh issue create --repo "$REPO" --title "$tag [$sev] $title" --label "$LABELS" --body "$body" >/dev/null
  echo "[+] Issue creado para finding $id ($sev)"
  creados=$((creados+1))
done < "$tmp"
echo "Listo. Issues creados: $creados"
