#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="devops-portfolio"
PVC="zap-reports"
POD="zap-report-extractor"
OUTPUT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/reportes"

cleanup() {
  kubectl delete pod "${POD}" -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
}

trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"

kubectl delete pod "${POD}" -n "${NAMESPACE}" --ignore-not-found

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD}
  namespace: ${NAMESPACE}
spec:
  restartPolicy: Never
  containers:
    - name: extractor
      image: busybox:1.36
      command: ["/bin/sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: reports
          mountPath: /zap/wrk/reports
  volumes:
    - name: reports
      persistentVolumeClaim:
        claimName: ${PVC}
EOF

kubectl wait \
  --for=condition=Ready \
  "pod/${POD}" \
  -n "${NAMESPACE}" \
  --timeout=120s

kubectl cp \
  "${NAMESPACE}/${POD}:/zap/wrk/reports/." \
  "${OUTPUT_DIR}/"

printf 'Reportes ZAP extraídos en: %s\n' "${OUTPUT_DIR}"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -printf '%f\n' | sort
