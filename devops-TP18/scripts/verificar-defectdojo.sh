#!/bin/bash
set -uo pipefail

echo "=========================================================="
echo "  VERIFICACION Y CARGA LOCAL A DEFECTDOJO API v2 (TP18)"
echo "=========================================================="
echo ""

DEFECTDOJO_URL="${DEFECTDOJO_URL:-http://defectdojo.local:18080}"
API_KEY="${DEFECTDOJO_API_KEY:-tu_api_key_v2_aqui}"
PRODUCT_NAME="${PRODUCT_NAME:-Notes App}"

import_scan() {
  local SCAN_TYPE="$1"
  local FILE_PATH="$2"

  if [ -f "$FILE_PATH" ]; then
    echo "  [+] Enviando $SCAN_TYPE ($FILE_PATH) a DefectDojo..."
    CODE=$(curl -s -o /tmp/dd-resp.json -w '%{http_code}' -X POST "$DEFECTDOJO_URL/api/v2/import-scan/" \
       -H "Authorization: Token $API_KEY" \
       -F "product_name=$PRODUCT_NAME" \
       -F "scan_type=$SCAN_TYPE" \
       -F "engagement_name=CI/CD Automated Security Audits" \
       -F "auto_create_context=true" \
       -F "file=@$FILE_PATH")
    # Antes se hacia grep de "id" en la respuesta: un error tambien la contiene (falso OK). Se valida el HTTP code.
    if [ "$CODE" -ge 200 ] && [ "$CODE" -lt 300 ]; then
      echo "      [OK] HTTP $CODE - importacion exitosa de $SCAN_TYPE"
    else
      echo "      [FAIL] HTTP $CODE: $(head -c 300 /tmp/dd-resp.json)"
    fi
  else
    echo "  [WARN] Archivo $FILE_PATH no encontrado. Genera el reporte previo."
  fi
}

# Nombres de scan_type tomados de los parsers del propio repo (django-DefectDojo/dojo/tools/*)
import_scan "ZAP Scan"               "reports-json/zap-results.xml"              # TP13C (el parser ZAP Scan espera XML)
import_scan "Threagile risks report" "reports-json/threagile-results.json"       # TP14: DEBE ser el risks.json real de Threagile
                                                                                 # (antes: "Generic CI/CD Audit", que no existe)
import_scan "Semgrep JSON Report"    "reports-json/semgrep-results.json"         # TP15
import_scan "Trivy Scan"             "reports-json/trivy-container-results.json" # TP16
import_scan "Gitleaks Scan"          "reports-json/gitleaks-report.json"         # TP17

echo ""
echo "=== Verificacion completada ==="
