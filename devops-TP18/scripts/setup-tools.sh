#!/usr/bin/env bash
# Instala en ~/.local/bin las herramientas de seguridad con versiones FIJAS (supply chain).
# Uso: scripts/setup-tools.sh hadolint gitleaks trivy syft kube-linter helm semgrep checkov
# Si un 404 aparece, la version cambio de nombre de asset: ajusta las variables de abajo.
set -Eeuo pipefail

HADOLINT_VERSION=2.12.0
GITLEAKS_VERSION=8.18.2
TRIVY_VERSION=0.57.1
SYFT_VERSION=1.18.1
KUBELINTER_VERSION=0.7.1
HELM_VERSION=3.13.0

BIN="$HOME/.local/bin"; mkdir -p "$BIN"; export PATH="$BIN:$PATH"
[ -n "${GITHUB_PATH:-}" ] && echo "$BIN" >> "$GITHUB_PATH"

case "$(uname -m)" in
  x86_64|amd64)  A_HADO=x86_64; A_GL=x64;   A_TRIVY=64bit; A_GO=amd64 ;;
  aarch64|arm64) A_HADO=arm64;  A_GL=arm64; A_TRIVY=ARM64; A_GO=arm64 ;;
  *) echo "Arquitectura no soportada: $(uname -m)"; exit 1 ;;
esac

dl() { curl -fsSL --retry 3 "$1" -o "$2"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

for tool in "$@"; do
  command -v "$tool" >/dev/null 2>&1 && { echo "[=] $tool ya disponible"; continue; }
  echo "[+] instalando $tool"
  case "$tool" in
    hadolint)    dl "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-${A_HADO}" "$BIN/hadolint"; chmod +x "$BIN/hadolint" ;;
    gitleaks)    dl "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${A_GL}.tar.gz" "$tmp/g.tgz"; tar -xzf "$tmp/g.tgz" -C "$BIN" gitleaks ;;
    trivy)       dl "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${A_TRIVY}.tar.gz" "$tmp/t.tgz"; tar -xzf "$tmp/t.tgz" -C "$BIN" trivy ;;
    syft)        dl "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_${A_GO}.tar.gz" "$tmp/s.tgz"; tar -xzf "$tmp/s.tgz" -C "$BIN" syft ;;
    kube-linter) if [ "$A_GO" = arm64 ]; then f=kube-linter-linux_arm64.tar.gz; else f=kube-linter-linux.tar.gz; fi
                 dl "https://github.com/stackrox/kube-linter/releases/download/v${KUBELINTER_VERSION}/$f" "$tmp/k.tgz"; tar -xzf "$tmp/k.tgz" -C "$BIN" kube-linter ;;
    helm)        dl "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${A_GO}.tar.gz" "$tmp/h.tgz"; tar -xzf "$tmp/h.tgz" -C "$tmp"; mv "$tmp/linux-${A_GO}/helm" "$BIN/helm" ;;
    semgrep|checkov)
                 python3 -m pip --version >/dev/null 2>&1 || { echo "ERROR: el runner no tiene python3-pip (necesario para $tool)"; exit 1; }
                 python3 -m pip install --user --quiet "$tool" ;;
    *) echo "Herramienta desconocida: $tool"; exit 1 ;;
  esac
done
