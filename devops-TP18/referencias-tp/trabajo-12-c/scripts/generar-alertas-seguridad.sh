#!/bin/bash
set -euo pipefail

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
INGRESS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
URL="http://$NODE_IP:$INGRESS_PORT"

echo "=========================================================="
echo "  SIMULACIÓN DE ATAQUE / TRÁFICO ANÓMALO (TP12C)"
echo "=========================================================="
echo "Objetivo: $URL"
echo ""

echo "[1/2] Generando escaneo de rutas inexistentes (provocando errores HTTP 404/403)..."
for i in {1..50}; do
  curl -s -o /dev/null -w "%{http_code}\n" -H "Host: devops-portfolio.local" "$URL/admin-admin-$i" || true
done

echo ""
echo "[2/2] Simulando fuerza bruta de login (provocando errores HTTP 401)..."
for i in {1..30}; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "Host: devops-portfolio.local" "$URL/api/v1/login" -d '{"user":"admin","pass":"wrong"}' || true
done

echo ""
echo "=== Simulación completada ==="
echo "Verifica el estado de las alertas en: http://$NODE_IP:30090/alerts (Prometheus UI)"

