#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="devops-portfolio"
MONITORING_NAMESPACE="monitoring"

echo "=== TP13C - Verificación final ==="

echo
echo "1. Nodos:"
kubectl wait --for=condition=Ready nodes --all --timeout=120s
kubectl get nodes

echo
echo "2. Deployments:"
kubectl rollout status deployment/postgres -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/backend -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/frontend -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/prometheus -n "${MONITORING_NAMESPACE}" --timeout=120s
kubectl rollout status deployment/grafana -n "${MONITORING_NAMESPACE}" --timeout=120s

echo
echo "3. DaemonSets:"
kubectl rollout status daemonset/node-exporter -n "${MONITORING_NAMESPACE}" --timeout=120s
kubectl rollout status daemonset/cadvisor -n "${MONITORING_NAMESPACE}" --timeout=120s

echo
echo "4. Ingress y PVC:"
kubectl get ingress -n "${NAMESPACE}"
kubectl get pvc -n "${NAMESPACE}"

echo
echo "5. Backend health:"
curl --fail --silent \
  -H "Host: notes.local" \
  http://127.0.0.1:18080/health
echo

echo
echo "6. Backend metrics:"
curl --fail --silent \
  -H "Host: notes.local" \
  http://127.0.0.1:18080/metrics | head -5

echo
echo "7. Prometheus:"
curl --fail --silent http://127.0.0.1:9090/-/ready
echo
curl --fail --silent http://127.0.0.1:9090/api/v1/targets \
  | jq -r '.data.activeTargets[] | "\(.labels.job): \(.health)"'

echo
echo "8. Grafana:"
curl --fail --silent http://127.0.0.1:3000/api/health
echo

echo
echo "9. ZAP:"
kubectl get job zap-security-scan -n "${NAMESPACE}"
kubectl get pvc zap-reports -n "${NAMESPACE}"

echo
echo "=== VERIFICACIÓN TP13C FINALIZADA ==="
