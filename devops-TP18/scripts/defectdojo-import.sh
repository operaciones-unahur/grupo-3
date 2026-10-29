#!/usr/bin/env bash
# Ingesta un reporte en DefectDojo via API v2 usando REIMPORT:
#   - crea Product/Engagement/Test si no existen (auto_create_context)
#   - deduplica y CIERRA (Mitigated) los hallazgos que ya no aparecen (close_old_findings)
# Uso: scripts/defectdojo-import.sh "<scan_type>" <archivo> ["<test_title>"]
# Env: DEFECTDOJO_URL, DEFECTDOJO_API_KEY, PRODUCT_NAME, ENGAGEMENT_NAME
set -Eeuo pipefail

SCAN_TYPE="${1:?scan_type}"; FILE="${2:?archivo}"; TEST_TITLE="${3:-$SCAN_TYPE}"
: "${DEFECTDOJO_URL:?}"; : "${DEFECTDOJO_API_KEY:?}"
PRODUCT_NAME="${PRODUCT_NAME:-Notes App}"
ENGAGEMENT_NAME="${ENGAGEMENT_NAME:-TP18 CI/CD Automated Security Audits}"

if [ ! -s "$FILE" ]; then echo "[WARN] $FILE no existe o esta vacio: se omite $SCAN_TYPE"; exit 0; fi

echo "[+] $SCAN_TYPE <- $FILE"
code=$(curl -sS -o /tmp/dd-resp.json -w '%{http_code}' -X POST "$DEFECTDOJO_URL/api/v2/reimport-scan/" \
  -H "Authorization: Token $DEFECTDOJO_API_KEY" \
  -F "scan_type=$SCAN_TYPE" \
  -F "product_type_name=Research and Development" \
  -F "product_name=$PRODUCT_NAME" \
  -F "engagement_name=$ENGAGEMENT_NAME" \
  -F "test_title=$TEST_TITLE" \
  -F "auto_create_context=true" \
  -F "close_old_findings=true" \
  -F "deduplication_on_engagement=true" \
  -F "active=true" -F "verified=false" \
  -F "file=@$FILE")
if [ "$code" -ge 200 ] && [ "$code" -lt 300 ]; then
  echo "    [OK] HTTP $code"
else
  echo "    [FAIL] HTTP $code: $(head -c 400 /tmp/dd-resp.json)"; exit 1
fi
