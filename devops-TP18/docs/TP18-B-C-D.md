# TP18 B, C y D — DefectDojo en k3d + integración con GitHub + Self-Hosted Runner

Todo lo de esta guía está adaptado a **este repo** (chart vendorizado de DefectDojo 3.4.101, clúster `notes-cluster` del TP13C con ingress-nginx y `127.0.0.1:18080→80`, chart `devops-portfolio`).

## Orden de ejecución

```bash
cd devops-TP18

# TP18B — DefectDojo
./scripts/tp18b-02-instalar-defectdojo.sh          # crea secretos, helm dependency build, helm install
echo '127.0.0.1 defectdojo.local' | sudo tee -a /etc/hosts
kubectl -n defectdojo get pods -w                   # esperar Running / initializer Completed
./scripts/tp18b-03-verificar-api.sh                 # token + GET /api/v2/products/ (HTTP 200)

# GitHub (UI): Settings > Secrets and variables > Actions
#   Secret   DEFECTDOJO_API_KEY = <token del paso anterior>
#   Variable ANDON_CORD_ENFORCE = false   (true recién en el PIF)

# TP18D — Runner
GITHUB_PAT=ghp_xxx ./scripts/tp18d-01-instalar-arc.sh
./scripts/tp18d-02-verificar-runner.sh              # runner "Idle" en Settings > Actions > Runners

# Disparar el pipeline
gh workflow run devsecops-pipeline.yml --ref main && gh run watch
```

## Desvíos respecto de los instructivos (y por qué)

| Instructivo | Problema en este repo | Qué se hizo |
|---|---|---|
| TP18B Paso 2: `helm repo add … https://helm.defectdojo.org` | El README del chart vendorizado indica `https://charts.defectdojo.com` y el repo ya trae el chart | Se instala desde `django-DefectDojo/helm/defectdojo` (misma versión que el código) |
| TP18B Paso 3: sección `redis:` y `celery.broker: redis` | El chart 1.9.57 **aborta** si existe `redis:` (migró a Valkey) | `values-local.yaml` usa `valkey:` |
| TP18B Paso 3: contraseñas en `values-local.yaml` | Gitleaks/ASVS V15 (CWE-798); el propio PIF lo penaliza | Secrets creados con valores aleatorios (`tp18b-01`), nada en git |
| TP18B Paso 6: `jsonpath='{.items.status…}'` y `:8080` | Sin `[0]` no funciona; el clúster publica el Ingress en `127.0.0.1:18080` | `127.0.0.1 defectdojo.local` + `http://defectdojo.local:18080` |
| TP18B Paso 5: Ingress manual | El chart ya trae su Ingress | Se configura por values (`django.ingress`, `activateTLS: false`) |
| TP18D/Anexo A: `http://defectdojo-django…svc.cluster.local:8080` | El Service del chart expone el puerto **80** | URL interna sin `:8080`; además se agrega a `alternativeHosts` (si no, Django responde 400 DisallowedHost) |
| TP18D: `http://notesapp.devops-portfolio.svc:8080` | Ese Service no existe | `frontend-service` (80) / `backend-service` (5000) |
| TP18D workflow: ZAP con `-J` + scan type `ZAP Scan` | El parser `ZAP Scan` de DefectDojo lee **XML** | `zap-baseline.py -x zap-report.xml` |
| TP18D workflow: `upload-artifact` de reportes | Sube a GitHub Cloud reportes con datos sensibles (contradice el objetivo del runner local) | Se escanea e ingesta en el mismo job; solo se publica el SBOM |
| TP18D workflow: `kubectl apply` de ARC | Los CRDs superan el límite de annotations | `kubectl apply --server-side` |
| TP18D logs: `-l app=notesapp-runnerdeploy` | En ARC summerwind la label es `runner-deployment-name` | Corregido (verificar con `--show-labels`) |
| `defectdojo-ci.yml` (existente) | Está en `devops-TP18/.github/workflows/`: **GitHub no lo ejecuta** (solo lee la raíz) | El pipeline nuevo vive en `/.github/workflows/devsecops-pipeline.yml` |
| `verificar-defectdojo.sh` (existente) | `Generic CI/CD Audit` no es un scan_type válido; el `grep id` daba falsos OK | Threagile = `Threagile risks report`; se valida el HTTP code |
| Job "Build, SBOM y Firma (Cosign)" | No firmaba nada | Se renombró (Syft + Trivy). Cosign queda para el PIF |

## TP18C — Integración DefectDojo ↔ GitHub

1. **Actions (ingesta):** hecho en el workflow vía `scripts/defectdojo-import.sh` (API v2 `reimport-scan`: deduplica y marca **Mitigated** lo que ya no aparece, que es lo que pide el Anexo B, paso 7).
2. **Issues:** dos caminos.
   - *Nativo (legacy):* el código del repo todavía incluye `dojo/github/`, que se habilita en System Settings (“Enable GitHub integration”) y se configura en Configuration → GitHub con un PAT; luego, por producto. **Ojo:** la tabla de ediciones de la propia documentación del repo marca las integraciones de gestión de proyectos como exclusivas de DefectDojo Pro, así que probalo y no cuentes con que funcione.
   - *Garantizado:* `scripts/tp18c-findings-a-issues.sh` (lo ejecuta la Fase 4 en `main`) crea un Issue por cada hallazgo Critical/High activo, con título `[DD-<id>]` para no duplicar. Crea las labels `security` y `defectdojo` si faltan.
3. **Projects v2:** en el Project → ⋯ → *Workflows* → **Auto-add to project**, filtro `is:issue label:security`. Así los Issues aparecen solos en *Backlog*.
4. **Red:** como el runner está dentro del clúster, no hace falta ngrok/Cloudflare/Tailscale. DefectDojo solo necesita salida a `api.github.com` si usás la integración nativa.

## ⚠️ Riesgo: repo público + runner self-hosted

El repo se hizo público y el runner ejecuta código dentro de tu clúster. Mitigaciones ya incluidas: el workflow **no corre PRs de forks** (`head.repo.full_name == github.repository`), el runner es efímero, sin token de Kubernetes y con límites de recursos. Falta (a mano): Settings → Actions → General → *Fork pull request workflows from outside collaborators* → **Require approval for all outside collaborators**. Lo más seguro: volver el repo a **privado** apenas la cátedra lo permita, o registrar el runner solo mientras entregás.

## Pendiente / sin probar

* Estos archivos **no se ejecutaron contra un clúster real** (no tuve acceso). Validé sintaxis bash y YAML. Primera corrida: esperá ajustes (versiones de herramientas en `setup-tools.sh`, `python3-pip` en la imagen del runner, DNS dentro del contenedor de ZAP).
* La imagen `summerwind/actions-runner` y el sidecar Docker (dind) corren privilegiados: es una limitación conocida de ARC legacy + `docker build`. Alternativa moderna: `gha-runner-scale-set` con Kaniko/BuildKit rootless (PIF).
* ARC `summerwind` v0.23.7 está **deprecado**; se usa porque lo pide el TP18D.
* `reports-json/*` del repo son archivos de ejemplo (Threagile no tiene el formato real `risks.json`); el pipeline genera los reales.
* El chart `devops-portfolio` usa `TU_USUARIO/devops-portfolio` como imagen: hay que reemplazarlo y desplegar NotesApp antes de la Fase 3 (DAST), o se omite con un warning.
