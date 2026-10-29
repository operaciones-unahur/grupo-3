# TP16 — Escaneo de Seguridad de Contenedores, Dependencias e IaC con Trivy (Pipeline 3 Fases)

Integración de **Trivy** en la fábrica de software (CI/CD) aplicando la arquitectura de **3 Fases con Paso de Artefactos** y la resolución de falsos positivos mediante el patrón **Render First (TP10B)**.

## Matriz de Control e Integración (Formato CSV)

```csv
Fase / Job;Dominio Evaluado;Severidades;Exit Code;Acción ante Hallazgos;Evidencia
Fase 1: build-and-package;Compilación Docker;-;0;Exporta app-image.tar como artefacto;Artefacto en GitHub Actions
Fase 2A: trivy-andon-cord;SCA, Contenedor e IaC Renderizado (TP10B);HIGH, CRITICAL;1;Andon Cord: Detiene el pipeline y bloquea el despliegue;Resumen en $GITHUB_STEP_SUMMARY
Fase 2B: trivy-audit-report;Contenedores y Dependencias;LOW, MEDIUM;0;Informativo: Genera reporte de inspección;Artifact descargable + $GITHUB_STEP_SUMMARY
Fase 3: deploy-k8s-helm;Publicación y Despliegue;-;0;Promueve la imagen aprobada a Docker Hub y Helm;Release en Kubernetes

## TP17 — Detección de Secretos y Filtraciones en Git con Gitleaks

### Matriz de Control

| Job en Pipeline | Tipo de Evaluación | Exit Code | Acción ante Hallazgos | Evidencia Generada |
|---|---|---:|---|---|
| gitleaks-andon-cord | Secret scanning en historial Git | 1 | Andon Cord: Bloquea el pipeline | Resumen en $GITHUB_STEP_SUMMARY |
| gitleaks-audit-report | Reporte de inspección JSON | 0 | Informativo: Genera evidencia | Artifact JSON descargable |

### Script de Verificación

El script `scripts/verificar-gitleaks.sh` realiza una verificación técnica local de la integración de Gitleaks:

- Verifica la instalación local de Gitleaks.
- Verifica la configuración de los jobs de Gitleaks en GitHub Actions.
- Ejecuta un escaneo preventivo local sin analizar el historial Git.
- Informa el resultado de la verificación.

Ejecución:

    bash scripts/verificar-gitleaks.sh

Resultado de la verificación:

    [OK] Gitleaks instalado localmente (8.18.2)
    [OK] Workflow configurado correctamente con los jobs de Gitleaks
    no leaks found
    === Verificación del TP17 completada con éxito ===
