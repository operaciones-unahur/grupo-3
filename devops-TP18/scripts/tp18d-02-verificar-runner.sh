#!/usr/bin/env bash
# TP18D - Verificacion del runner en Kubernetes y en GitHub.
set -uo pipefail
NS=actions-runner-system
echo "--- RunnerDeployment / Runners";  kubectl -n $NS get runnerdeployments,runners
echo "--- Pods (con labels, para confirmar el selector de logs)"; kubectl -n $NS get pods --show-labels
echo
echo "En GitHub: repo > Settings > Actions > Runners => debe verse un runner 'Idle' con labels self-hosted, k3s-local"
echo
echo "Logs en vivo del runner:"
echo "  kubectl -n $NS logs -l runner-deployment-name=notesapp-runnerdeploy -c runner -f --tail=50"
echo "  (el instructivo usa '-l app=notesapp-runnerdeploy'; en ARC summerwind la label es runner-deployment-name."
echo "   Si no devuelve nada, mira la columna LABELS de arriba y ajusta.)"
echo "Consumo:  kubectl top pod -n $NS"
