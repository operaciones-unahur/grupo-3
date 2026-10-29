#!/usr/bin/env bash
# TP18B - Instala OWASP DefectDojo en k3s/k3d con Helm usando el chart vendorizado del repo
# (misma version que el codigo de django-DefectDojo/ => values que coinciden).
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
NS="${DD_NAMESPACE:-defectdojo}"
CHART="$HERE/django-DefectDojo/helm/defectdojo"
VALUES="$HERE/defectdojo-k8s/values-local.yaml"

command -v helm >/dev/null || { echo "Falta helm (>= 3.8, necesita soporte OCI)"; exit 1; }
[ -d "$CHART" ] || { echo "No existe $CHART"; exit 1; }

"$HERE/scripts/tp18b-01-crear-secretos.sh"

echo "==> helm dependency build (descarga postgresql y valkey desde registries OCI; requiere Internet)"
helm dependency build "$CHART"

echo "==> helm upgrade --install defectdojo"
helm upgrade --install defectdojo "$CHART" \
  --namespace "$NS" \
  -f "$VALUES" \
  --timeout 15m

cat <<MSG

==> Monitoreo (espera initializer Completed y el resto Running; 3-6 min):
    kubectl -n $NS get pods -w

==> Resolucion local (el cluster del TP13C publica 127.0.0.1:18080 -> 80):
    echo '127.0.0.1 defectdojo.local' | sudo tee -a /etc/hosts
    URL: http://defectdojo.local:18080   usuario: admin   (password en .secrets/defectdojo-admin.txt)

==> Alternativa sin Ingress ni /etc/hosts:
    kubectl -n $NS port-forward svc/defectdojo-django 8080:80   ->  http://localhost:8080
MSG
