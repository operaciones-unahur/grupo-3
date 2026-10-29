#!/usr/bin/env bash
# TP18D - Pasos 1 a 5: cert-manager + ARC + secret con PAT + RunnerDeployment.
# Uso:  GITHUB_PAT=ghp_xxx ./scripts/tp18d-01-instalar-arc.sh
# (El PAT necesita scope "repo" y que tu usuario sea admin del repo operaciones-unahur/grupo-3.)
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${GITHUB_PAT:?Exporta GITHUB_PAT con un Personal Access Token (scope repo)}"

echo "==> 1/5 cert-manager v1.13.2"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
kubectl -n cert-manager wait --for=condition=Available deployment --all --timeout=300s

echo "==> 2/5 ARC v0.23.7 (server-side: los CRDs superan el limite de annotations de 'apply' normal)"
kubectl apply --server-side --force-conflicts -f \
  https://github.com/actions/actions-runner-controller/releases/download/v0.23.7/actions-runner-controller.yaml

echo "==> 3/5 Secret con el PAT (no queda en git ni en el historial de comandos)"
kubectl -n actions-runner-system create secret generic controller-manager \
  --from-literal=github_token="$GITHUB_PAT" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n actions-runner-system rollout restart deployment/controller-manager || true
kubectl -n actions-runner-system rollout status deployment/controller-manager --timeout=300s

echo "==> 4/5 RunnerDeployment"
kubectl apply -f "$HERE/runner-k8s/runnerdeployment.yaml"

echo "==> 5/5 Estado"
"$HERE/scripts/tp18d-02-verificar-runner.sh"
