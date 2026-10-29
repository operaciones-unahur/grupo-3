#!/bin/bash
set -uo pipefail

echo "=========================================================="
echo "  VERIFICACIÓN Y CARGA LOCAL A DEFECTDOJO API v2 (TP18)"
echo "=========================================================="
echo ""

DEFECTDOJO_URL="${DEFECTDOJO_URL:-http://localhost:8080}"
API_KEY="${DEFECTDOJO_API_KEY:-tu_api_key_v2_aqui}"
PRODUCT_ID="${PRODUCT_ID:-1}"
PRODUCT_NAME="${PRODUCT_NAME:-Notes App}"

import_scan() {
  local SCAN_TYPE="$1"
  local FILE_PATH="$2"

  if [ -f "$FILE_PATH" ]; then
    echo "  [+] Enviando $SCAN_TYPE ($FILE_PATH) a DefectDojo..."
    RESPONSE=$(curl -s -X POST "$DEFECTDOJO_URL/api/v2/import-scan/" \
       -H "Authorization: Token $API_KEY" \
       -F "product_id=$PRODUCT_ID" \
       -F "product_name=$PRODUCT_NAME" \
       -F "scan_type=$SCAN_TYPE" \
       -F "engagement_name=CI/CD Automated Security Audits" \
       -F "auto_create_context=true" \
       -F "file=@$FILE_PATH")

    if echo "$RESPONSE" | grep -q "scan_type\|id"; then
      echo "      [OK] Importación exitosa de $SCAN_TYPE"
    else
      echo "      [FAIL] Error en importación: $RESPONSE"
    fi
  else
    echo "  [WARN] Archivo $FILE_PATH no encontrado. Genera el reporte previo."
  fi
}

# Importaciones locales
import_scan "ZAP Scan" "reports-json/zap-results.xml"                     # TP13C (ZAP XML)
import_scan "Generic CI/CD Audit" "reports-json/threagile-results.json"   # TP14 (Threagile)
import_scan "Semgrep JSON Report" "reports-json/semgrep-results.json"     # TP15 (Semgrep)
import_scan "Trivy Scan" "reports-json/trivy-container-results.json"     # TP16 (Trivy)
import_scan "Gitleaks Scan" "reports-json/gitleaks-report.json"          # TP17 (Gitleaks)

echo ""
echo "=== Verificación completada ==="
