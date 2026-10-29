#!/usr/bin/env bash
# TP18B - Pasos 8 y 9: obtiene el token API v2 y verifica el endpoint.
# Uso:  DEFECTDOJO_URL=http://defectdojo.local:18080 ./scripts/tp18b-03-verificar-api.sh
set -Eeuo pipefail

URL="${DEFECTDOJO_URL:-http://defectdojo.local:18080}"
NS="${DD_NAMESPACE:-defectdojo}"
USER_DD="${DD_ADMIN_USER:-admin}"
PASS="$(kubectl -n "$NS" get secret defectdojo -o jsonpath='{.data.DD_ADMIN_PASSWORD}' | base64 -d)"

echo "==> POST $URL/api/v2/api-token-auth/"
TOKEN="$(curl -fsS -X POST "$URL/api/v2/api-token-auth/" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER_DD\",\"password\":\"$PASS\"}" | jq -r .token)"
[ -n "$TOKEN" ] && [ "$TOKEN" != "null" ] || { echo "No se obtuvo token"; exit 1; }

echo "==> GET /api/v2/products/ (espera HTTP 200)"
curl -s -o /dev/null -w 'HTTP %{http_code}\n' "$URL/api/v2/products/" -H "Authorization: Token $TOKEN"

cat <<MSG

Cargalo como Secret de GitHub (Settings > Secrets and variables > Actions):
  DEFECTDOJO_API_KEY = <el token>      (no lo pegues en el repo ni en chats)
Token (solo en esta terminal):
  $TOKEN

El runner usa la URL INTERNA (no hace falta secret para eso):
  http://defectdojo-django.defectdojo.svc.cluster.local   (puerto 80)
MSG
