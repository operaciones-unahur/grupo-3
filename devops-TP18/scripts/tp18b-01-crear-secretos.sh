#!/usr/bin/env bash
# TP18B - Paso previo: crea los Secrets de DefectDojo con valores aleatorios.
# Nada de contrasenas en git. Las credenciales quedan SOLO en .secrets/ (ignorado por git).
set -Eeuo pipefail

NS="${DD_NAMESPACE:-defectdojo}"
SECRETS_DIR="$(cd "$(dirname "$0")/.." && pwd)/.secrets"
rand() { openssl rand -hex "${1:-16}"; }

kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS"
mkdir -p "$SECRETS_DIR"; chmod 700 "$SECRETS_DIR"

crear_si_no_existe() {   # $1 = nombre del secret, resto = args de "kubectl create secret generic"
  local name="$1"; shift
  if kubectl -n "$NS" get secret "$name" >/dev/null 2>&1; then
    echo "[=] Secret $name ya existe: no se toca."
    return 1
  fi
  kubectl -n "$NS" create secret generic "$name" "$@"
  echo "[+] Secret $name creado."
}

ADMIN_PASS="$(rand 12)"
PG_PASS="$(rand 16)"
VK_PASS="$(rand 16)"

if crear_si_no_existe defectdojo \
     --from-literal=DD_ADMIN_PASSWORD="$ADMIN_PASS" \
     --from-literal=DD_SECRET_KEY="$(rand 32)" \
     --from-literal=DD_CREDENTIAL_AES_256_KEY="$(rand 32)" \
     --from-literal=METRICS_HTTP_AUTH_PASSWORD="$(rand 16)"; then
  ( umask 077; printf 'usuario: admin\npassword: %s\n' "$ADMIN_PASS" > "$SECRETS_DIR/defectdojo-admin.txt" )
  echo "Credenciales de admin guardadas en: $SECRETS_DIR/defectdojo-admin.txt"
fi

crear_si_no_existe defectdojo-postgresql-specific \
  --from-literal=postgresql-postgres-password="$PG_PASS" \
  --from-literal=postgresql-password="$PG_PASS" || true

crear_si_no_existe defectdojo-valkey-specific \
  --from-literal=valkey-password="$VK_PASS" || true

echo "Recuperar la password de admin del cluster:"
echo "  kubectl -n $NS get secret defectdojo -o jsonpath='{.data.DD_ADMIN_PASSWORD}' | base64 -d; echo"
