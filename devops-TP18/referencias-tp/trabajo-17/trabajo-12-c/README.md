# TP12C — Alertas de Ciberseguridad y Detección de Anomalías

## Objetivo

Implementación de alertas de ciberseguridad y detección de anomalías para la Notes App utilizando Prometheus y Grafana.

## Implementación

Se incorporaron:

- Reglas de alerta de Prometheus en `prometheus-alerts-security.yml`.
- Configuración de Prometheus en `prometheus.yml`.
- Dashboard de Grafana `Sad Paths & Security Events` en `app-dashboard.json`.
- Simulación de tráfico anómalo en `scripts/generar-alertas-seguridad.sh`.
- Backend TP12C en `tp12c-app/`.
- Manifiestos Kubernetes en `manifests/`.

## Alertas configuradas

El grupo `AlertasSeguridadNotesApp` contiene cuatro reglas:

1. `IngressPicoErrores4xx5xx`
2. `PodReiniciosFrecuentesSeguridad`
3. `InvasionIntentosAuthFallidos`
4. `PicoErroresConexionBaseDatos`

## Evidencia de funcionamiento

Durante las pruebas se verificó el disparo de:

- `InvasionIntentosAuthFallidos` — estado `firing`.
- `PicoErroresConexionBaseDatos` — estado `firing`.

El dashboard de Grafana contiene tres paneles:

- Errores HTTP 401/403/500.
- Reinicios de Pods.
- Errores de Base de Datos.

## Simulación

El script `scripts/generar-alertas-seguridad.sh` genera tráfico anómalo mediante:

- solicitudes a rutas inexistentes para provocar errores HTTP;
- intentos fallidos de autenticación.

## Entorno

- Kubernetes / k3d
- Prometheus
- Grafana
- kube-state-metrics
- NGINX Ingress Controller
- Notes App
- PostgreSQL
