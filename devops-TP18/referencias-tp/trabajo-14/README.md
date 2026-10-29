# TP14 — Modelado de amenazas con Threagile

## Objetivo

En esta guía vas a integrar Threagile al pipeline de CI/CD de la Notes App. El objetivo es describir la arquitectura que construiste hasta TP12, analizar sus riesgos y generar un reporte actualizado cada vez que cambie el modelo.

Threagile es una herramienta de modelado de amenazas. La arquitectura se escribe en un archivo YAML que se guarda junto con el código. De esta manera, el modelo puede validarse en la computadora del alumno y también desde GitHub Actions.

## Prerrequisitos

- Docker, Git, Python 3 con PyYAML y un repositorio de GitHub configurado.
- Base integrada hasta TP12. Su preparación completa, TLS y comprobaciones están en [`devops-tp12/README.md`](devops-tp12/README.md).
- Pipeline previo en `.github/workflows/cicd.yml`.

Esta versión fue comprobada con Threagile 1.0.0. Los identificadores de riesgo pueden cambiar entre versiones; por eso se obtienen de la primera ejecución y no se escriben de memoria.

## Mapa de carpetas

```text
raíz-del-repositorio/             # ejecutar Git y editar .github aquí
├── .github/workflows/cicd.yml
├── .yamllint.yml                 # reglas usadas por el job de lint
├── devops-tp12/                 # proyecto integrado y modelo TP14
│   ├── app/ chart/ scripts/
│   └── threagile.yaml           # lo crearás; no viene resuelto
├── devops-TP06/                 # copia histórica usada por jobs previos
├── guia-06/                     # Docker Compose
├── guia-08/                     # Prometheus y Grafana
├── guia-09/                     # Kubernetes
├── guia-10/                     # Helm e Ingress
├── guia-11/                     # Terraform
└── guia-12/                     # portfolio integrado
```

Las carpetas `guia-06` a `guia-12` se conservan como antecedentes y material de los trabajos previos. En TP14 no hay que editarlas: el procedimiento se realiza sobre `devops-tp12/` y sobre el workflow de la raíz.

Al abrir una terminal, entrá en el repositorio:

```bash
cd guia-14-para-alumnos
```

## Paso 1: Preparar tu entorno de trabajo local.

Directorio: raíz del repositorio.

Si todavía no preparaste la base, seguí `devops-tp12/README.md` antes de continuar. La configuración TLS forma parte de esa base integrada y no agrega un paso nuevo al TP14.

## Paso 2: Generar un modelo de amenazas inicial (Stub Model).

Directorio: proyecto integrado.

```bash
cd devops-tp12
docker run --rm -it -v "$(pwd)":/app/work threagile/threagile:latest \
  --create-stub-model --output /app/work
```

El contenedor crea `threagile-stub-model.yaml` en la carpeta actual. La opción `-it` permite ver la ejecución en una terminal interactiva.

## Paso 3: Renombrar la plantilla para que sea tu modelo oficial.

```bash
mv threagile-stub-model.yaml threagile.yaml
```

## Paso 4: Adaptar el modelo a la arquitectura de la Notes App.

Abrí el archivo desde `devops-tp12/`:

```bash
nano threagile.yaml
```

Reemplazá todo por el bloque siguiente. En nano: `Ctrl+O`, `Enter` para guardar y `Ctrl+X` para salir.

<!-- BEGIN THREAGILE_MODEL -->
```yaml
threagile_version: 1.0.0

title: Notes App - Amenazas (TP14)
date: 2026-09-05
author:
  name: Equipo DevOps - Notes App
  homepage: https://github.com/TU_USUARIO/devops-tp12

business_criticality: important

data_assets:
  credenciales-usuario:
    id: credenciales-usuario
    description: Usuario y contraseña de laboratorio usados por el administrador para acceder a Grafana.
    usage: business
    quantity: few
    confidentiality: confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Comprometer estas credenciales expone los paneles y la configuración de observabilidad.

  credenciales-registro:
    id: credenciales-registro
    description: Usuario y token de Docker Hub almacenados como Secrets de GitHub Actions para publicar la imagen histórica del backend.
    usage: devops
    quantity: few
    confidentiality: strictly-confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Su exposición permitiría publicar o alterar imágenes en el repositorio autorizado.

  contenido-notas:
    id: contenido-notas
    description: Título y contenido de las notas creadas por los usuarios de la aplicación.
    usage: business
    quantity: many
    confidentiality: internal
    integrity: important
    availability: operational
    justification_cia_rating: Es el dato de negocio principal de la aplicación; su pérdida afecta a los usuarios.

  credenciales-bd:
    id: credenciales-bd
    description: Usuario y contraseña de PostgreSQL utilizados por el backend para conectarse a la base de datos.
    usage: business
    quantity: few
    confidentiality: strictly-confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Su exposición permite acceso directo no autorizado a toda la base de datos.

  metricas-monitoreo:
    id: metricas-monitoreo
    description: Series de tiempo de métricas de aplicación, host y contenedores recolectadas por Prometheus.
    usage: devops
    quantity: many
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Son datos operativos de bajo impacto directo sobre el negocio, pero relevantes para observabilidad.

  token-service-account-prometheus:
    id: token-service-account-prometheus
    description: Token de la ServiceAccount "prometheus-sa" que autentica a Prometheus contra el API Server de Kubernetes para el service discovery dinámico (RBAC vía ClusterRole/ClusterRoleBinding, de solo lectura sobre pods/services/endpoints/nodes).
    usage: devops
    quantity: few
    confidentiality: strictly-confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Si se filtra, permite listar pods, services, endpoints y nodes de todo el clúster (alcance ClusterRole, no sólo del namespace).

  metadata-descubrimiento-k8s:
    id: metadata-descubrimiento-k8s
    description: Lista de Pods y Endpoints (IP, puerto, labels) que el API Server devuelve a Prometheus en cada consulta de service discovery -- de ahí sale qué targets scrapear.
    usage: devops
    quantity: few
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Es metadata operativa del clúster (topología de Pods/Endpoints), no datos de negocio; su alteración podría hacer que Prometheus deje de scrapear targets reales.

technical_assets:

  cliente-web:
    id: cliente-web
    title: Navegador Web (Usuario Externo)
    description: El cliente HTTP (navegador) en el dispositivo del usuario que inicia el acceso a la Notes App a través de internet de forma pública.
    type: external-entity
    usage: business
    used_as_client_by_human: true
    size: component
    technology: browser
    internet: true
    machine: physical
    encryption: none
    owner: Usuario externo
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Es un dispositivo fuera del control del equipo DevOps.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
    communication_links:
      peticiones_usuario:
        target: ingress-controller
        title: Envío de Peticiones de Usuario
        description: Tráfico HTTPS hacia el Ingress para usar la interfaz y las operaciones de consulta, creación y eliminación de notas.
        protocol: https
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas

  ingress-controller:
    id: ingress-controller
    title: Ingress Controller (nginx, Kubernetes)
    description: Ingress de Kubernetes (ingress-nginx) que termina TLS y enruta por path hacia los Services internos - "/" al frontend, "/api" y "/health" directo al backend - según el chart Helm de TP10.
    type: process
    usage: business
    size: component
    technology: load-balancer
    internet: true
    machine: container
    encryption: transparent
    owner: Equipo DevOps
    confidentiality: internal
    integrity: important
    availability: important
    justification_cia_rating: Es la única puerta de entrada pública hacia el clúster; termina TLS antes de reenviar el tráfico a los Pods internos.
    multi_tenant: false
    redundant: true
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
    communication_links:
      routing_frontend:
        target: nginx
        title: Enrutamiento a Frontend (path /)
        description: Reenvía el tráfico del path "/" al Service frontend-service dentro del clúster.
        protocol: http
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas
      routing_backend:
        target: backend
        title: Enrutamiento a Backend (paths /api y /health)
        description: Reenvía el tráfico de los paths "/api" y "/health" directo al Service backend-service, sin pasar por nginx.
        protocol: http
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas

  nginx:
    id: nginx
    title: Frontend Nginx (Pod)
    description: Pod Nginx que sirve el frontend estático de la Notes App detrás del Ingress.
    type: process
    usage: business
    size: component
    technology: web-server
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: important
    availability: important
    justification_cia_rating: Sirve la interfaz al usuario; sólo recibe tráfico ya filtrado por el Ingress.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas

  backend:
    id: backend
    title: Backend Flask/Gunicorn (WSGI)
    description: Servidor de aplicación que gestiona la lógica de las notas y expone métricas internas para Prometheus.
    type: process
    usage: business
    size: component
    technology: web-service-rest
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Procesa las credenciales de base de datos y de usuario, y toda la lógica de negocio de las notas.
    multi_tenant: false
    redundant: false
    custom_developed_parts: true
    data_assets_processed:
      - contenido-notas
      - credenciales-bd
    data_formats_accepted:
      - json
    communication_links:
      conexion_base_datos:
        target: postgres
        title: Conexión de Base de Datos (psycopg2)
        description: Conexión de red activa iniciada por la app de Flask para realizar consultas de inserción y lectura en PostgreSQL.
        protocol: sql-access-protocol
        authentication: credentials
        authorization: technical-user
        usage: business
        data_assets_sent:
          - contenido-notas
          - credenciales-bd

  postgres:
    id: postgres
    title: Base de Datos PostgreSQL
    description: Base de datos relacional PostgreSQL encargada de resguardar los datos de las notas de forma persistente.
    type: datastore
    usage: business
    size: component
    technology: database
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Almacena de forma persistente todas las notas y depende de ella toda la aplicación.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - contenido-notas
      - credenciales-bd
    data_assets_stored:
      - contenido-notas
      - credenciales-bd
    communication_links:
      escritura_volumen:
        target: volumen-postgres
        title: Escritura en Disco (PVC)
        description: PostgreSQL escribe sus archivos de datos en el PersistentVolumeClaim montado (almacenamiento local del clúster k3d).
        protocol: local-file-access
        authentication: none
        authorization: none
        usage: business
        data_assets_sent:
          - contenido-notas
          - credenciales-bd

  kubernetes-api-server:
    id: kubernetes-api-server
    title: API Server de Kubernetes
    description: Plano de control del clúster. Prometheus lo consulta para el service discovery dinámico (kubernetes_sd_configs) en vez de usar hostnames fijos, autenticado con el token de la ServiceAccount "prometheus-sa" y autorizado por un ClusterRole de solo lectura (pods, services, endpoints, nodes).
    type: process
    usage: devops
    size: system
    technology: application-server
    internet: false
    machine: container
    encryption: transparent
    owner: Equipo DevOps
    confidentiality: strictly-confidential
    integrity: mission-critical
    availability: mission-critical
    justification_cia_rating: Es el plano de control de todo el clúster; comprometerlo compromete todo lo demás.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metadata-descubrimiento-k8s

  prometheus:
    id: prometheus
    title: Servidor Metricas Prometheus
    description: Sistema de monitoreo que recopila (scrapes) las métricas de rendimiento del ecosistema de la Notes App, y descubre sus targets (backend, node-exporter, cadvisor) de forma dinámica consultando al API Server de Kubernetes por label, en vez de usar hostnames fijos.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Consolida métricas operativas; no almacena datos de negocio de los usuarios.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo
      - token-service-account-prometheus
      - metadata-descubrimiento-k8s
    data_assets_stored:
      - metricas-monitoreo
    communication_links:
      service_discovery_k8s_api:
        target: kubernetes-api-server
        title: Service Discovery dinámico (RBAC)
        description: Prometheus consulta al API Server con el token de "prometheus-sa" para descubrir Pods con label app=backend y los Endpoints de node-exporter/cadvisor (kubernetes_sd_configs, roles pod y endpoints).
        protocol: https
        authentication: token
        authorization: technical-user
        usage: devops
        readonly: true
        data_assets_sent:
          - token-service-account-prometheus
        data_assets_received:
          - metadata-descubrimiento-k8s
      scrape_backend:
        target: backend
        title: Recolección de métricas de App
        description: Peticiones de scraping HTTP GET periódicas hacia el endpoint /metrics del Backend de Flask (Service backend-service); las métricas viajan en la respuesta, no en el pedido.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_received:
          - metricas-monitoreo
      scrape_node_exporter:
        target: node-exporter
        title: Recolección de métricas de Host
        description: Peticiones HTTP periódicas hacia el Service node-exporter en el puerto 9100; las métricas viajan en la respuesta, no en el pedido.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_received:
          - metricas-monitoreo
      scrape_cadvisor:
        target: cadvisor
        title: Recolección de métricas de Contenedores
        description: Peticiones HTTP periódicas al Service cAdvisor en el puerto 8080 para monitorear los contenedores del clúster; las métricas viajan en la respuesta, no en el pedido.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_received:
          - metricas-monitoreo

  grafana:
    id: grafana
    title: Visualizador Grafana
    description: Plataforma web interactiva para visualizar dashboards basados en las métricas consolidadas.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Solo visualiza métricas ya consolidadas por Prometheus.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo
      - credenciales-usuario
    communication_links:
      consulta_datos_prometheus:
        target: prometheus
        title: Consulta de Métricas de Monitoreo
        description: Peticiones HTTP periódicas dirigidas al Service prometheus en el puerto 9090 para obtener la información de los gráficos en tiempo real; las métricas viajan en la respuesta, no en el pedido.
        protocol: http
        authentication: none
        authorization: none
        usage: devops
        readonly: true
        data_assets_received:
          - metricas-monitoreo

  node-exporter:
    id: node-exporter
    title: Agente NodeExporter
    description: DaemonSet que expone de forma pasiva las métricas del hardware de cada nodo del clúster.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Expone métricas de solo lectura del host, sin datos de negocio.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo

  cadvisor:
    id: cadvisor
    title: Agente cAdvisor
    description: DaemonSet encargado de exponer de forma pasiva las métricas de rendimiento internas de los contenedores del clúster.
    type: process
    usage: devops
    size: component
    technology: monitoring
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: internal
    integrity: operational
    availability: operational
    justification_cia_rating: Expone métricas de solo lectura de contenedores, sin datos de negocio.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - metricas-monitoreo

  volumen-postgres:
    id: volumen-postgres
    title: PVC de Datos Postgres
    description: PersistentVolumeClaim de Kubernetes donde PostgreSQL guarda físicamente los archivos de la base de datos.
    type: datastore
    usage: business
    size: component
    technology: local-file-system
    internet: false
    machine: container
    encryption: none
    owner: Equipo DevOps
    confidentiality: confidential
    integrity: critical
    availability: important
    justification_cia_rating: Es el almacenamiento físico final de todos los datos de la base; su pérdida es irreversible.
    multi_tenant: false
    redundant: false
    custom_developed_parts: false
    data_assets_stored:
      - contenido-notas
      - credenciales-bd

  docker-registry:
    id: docker-registry
    title: Registro Docker Hub
    description: Registro público donde el pipeline de CI/CD publica la imagen del backend.
    type: process
    usage: devops
    size: component
    technology: artifact-registry
    internet: true
    machine: serverless
    encryption: transparent
    owner: Docker Hub (terceros)
    confidentiality: internal
    integrity: important
    availability: operational
    justification_cia_rating: Un push accidental o no controlado a un registro público expondría las imágenes de la aplicación.
    multi_tenant: true
    redundant: false
    custom_developed_parts: false
    data_assets_processed:
      - credenciales-registro

  github-actions-pipeline:
    id: github-actions-pipeline
    title: Pipeline GitHub Actions
    description: Runner externo que construye y publica en Docker Hub la imagen del backend histórico desde main o develop.
    type: process
    usage: devops
    size: service
    technology: build-pipeline
    internet: true
    machine: serverless
    encryption: transparent
    owner: Equipo DevOps / GitHub
    confidentiality: confidential
    integrity: critical
    availability: operational
    justification_cia_rating: Controla la publicación de imágenes y se ejecuta fuera del clúster local.
    multi_tenant: true
    redundant: true
    custom_developed_parts: false
    data_assets_processed:
      - credenciales-registro
    communication_links:
      publica-backend-historico:
        target: docker-registry
        title: Push de imagen a Docker Hub
        description: Publicación HTTPS autenticada del backend histórico desde main o develop; no publica la app integrada.
        protocol: https
        authentication: credentials
        authorization: technical-user
        usage: devops
        data_assets_sent:
          - credenciales-registro

trust_boundaries:
  cluster-kubernetes:
    id: cluster-kubernetes
    description: Clúster k3d local completo; agrupa los contenedores y el volumen para evaluar riesgos en las fronteras de red.
    type: network-on-prem
    technical_assets_inside:
      - ingress-controller
      - nginx
      - backend
      - postgres
      - volumen-postgres
      - prometheus
      - grafana
      - node-exporter
      - cadvisor
      - kubernetes-api-server

risk_tracking:
  unencrypted-communication@backend>conexion-base-datos@backend@postgres:
    status: accepted
    justification: >-
      La conexión psycopg2 usa el protocolo PostgreSQL sin TLS. Se acepta en
      este laboratorio local porque backend y PostgreSQL son ClusterIP dentro
      del clúster k3d y no se publica el puerto 5432. El riesgo residual se
      acepta porque el laboratorio no utiliza NetworkPolicy.
    ticket: TP14-02
    date: 2026-09-06
    checked_by: Equipo DevOps

  unchecked-deployment@docker-registry:
    status: accepted
    justification: >-
      Los Secrets DOCKERHUB_USERNAME y DOCKERHUB_TOKEN controlan el acceso al
      registro. El workflow publica el backend histórico desde main y develop
      sin aprobación manual, por lo que el riesgo residual queda aceptado.
    ticket: TP14-03
    date: 2026-09-06
    checked_by: Equipo DevOps

  missing-vault@kubernetes-api-server:
    status: accepted
    justification: >-
      Kubernetes monta el token efímero de prometheus-sa. El ClusterRole sólo
      permite get/list/watch de pods, services, endpoints y nodes, no Secrets.
      El laboratorio no incorpora un vault externo.
    ticket: TP14-04
    date: 2026-09-06
    checked_by: Equipo DevOps
```
<!-- END THREAGILE_MODEL -->

Antes de guardar, reemplazá `TU_USUARIO` por tu usuario de GitHub. No cambies los identificadores del modelo: el bloque de `risk_tracking` depende de ellos.

Las cinco partes conceptuales son:

1. Cabecera: versión de Threagile, título, fecha, autor y criticidad.
2. `data_assets`: notas, credenciales de PostgreSQL, credenciales de Grafana, métricas, token/metadata de Kubernetes y credenciales del registro.
3. `technical_assets`: los siete componentes pedidos, cliente, PVC, Docker Hub y los activos reales Ingress, API Server y pipeline.
4. `trust_boundaries`: el clúster local se representa como `network-on-prem`; compartir namespace no demuestra aislamiento y no hay NetworkPolicy.
5. `risk_tracking`: decisiones sobre IDs que efectivamente produce el motor.

En Threagile 1.0.0 se utilizan `communication_links`, `target` e `internet`, y los identificadores llevan guiones. El modelo respeta las rutas reales de la aplicación: `/api` llega al backend y `/` al frontend Nginx. La conexión de psycopg2 se representa como `sql-access-protocol`.

TLS termina en el Ingress. Desde allí, los servicios internos se comunican por HTTP y el backend se conecta a PostgreSQL sin TLS. Esta diferencia es importante para interpretar los riesgos que aparecen en el reporte.

El límite `cluster-kubernetes` representa el clúster k3d completo. Reúne la aplicación, el monitoreo, ingress-nginx y el API Server, pero no implica que exista aislamiento interno mediante NetworkPolicy.

El activo `docker-registry` representa Docker Hub. El pipeline anterior publica allí la imagen del backend, mientras que las imágenes de la aplicación integrada se construyen en forma local y se cargan en k3d. Por ese motivo el modelo incluye también el activo `github-actions-pipeline` y su conexión con el registro.

### Tratamiento de riesgos

| Tema | Riesgo generado | Control | Tratamiento |
|---|---|---|---|
| Comunicación de entrada | No se genera porque cliente→Ingress usa HTTPS | TLS configurado en el Ingress | Mitigado en la entrada; los enlaces internos siguen sin TLS |
| Conexión con PostgreSQL | `unencrypted-communication@backend>conexion-base-datos@backend@postgres` | PostgreSQL es ClusterIP y el puerto 5432 no se publica | Aceptado para el laboratorio |
| Publicación en Docker Hub | `unchecked-deployment@docker-registry` | Acceso mediante Secrets de GitHub | Aceptado porque no exige aprobación manual |

## Paso 5: Validar la sintaxis de tu modelo localmente.

Ejecutá el modelo desde `devops-tp12/`:

```bash
docker run --rm -v "$(pwd)":/app/work threagile/threagile:latest \
  --verbose --model /app/work/threagile.yaml --output /app/work
```

Al terminar deben aparecer `report.pdf`, `data-flow-diagram.png` y `risks.json`. Los IDs de `risk_tracking` incluidos en el modelo fueron comprobados con Threagile 1.0.0.

## Paso 6: Integrar Threagile en tu Pipeline (cicd.yml).

Volvé a la raíz y editá el workflow real; no uses el de `devops-TP06/`.

```bash
cd ..
nano .github/workflows/cicd.yml
```

Al final de `jobs:`, al mismo nivel que los jobs existentes, pegá y guardá con `Ctrl+O`, `Enter`, `Ctrl+X`:

<!-- BEGIN THREAT_MODELING_JOB -->
```yaml
  threat-modeling:
    name: Threat Model Analysis
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Workspace
        uses: actions/checkout@v4
      - name: Run Threagile
        id: threagile
        uses: threagile/run-threagile-action@v1
        with:
          model-file: 'devops-tp12/threagile.yaml'
      - name: Verify generated reports
        run: |
          test -s threagile/output/report.pdf
          test -s threagile/output/data-flow-diagram.png
      - name: Archive Results
        uses: actions/upload-artifact@v4
        with:
          name: threagile-report
          path: threagile/output
          if-no-files-found: error
```
<!-- END THREAT_MODELING_JOB -->

Guardá el archivo sin reemplazar los jobs `lint`, `test`, `test-integrated-app` y `build-push`.

## Paso 7: Agregar los archivos al control de versiones de Git.

Desde la raíz del repositorio:

```bash
git add devops-tp12/threagile.yaml .github/workflows/cicd.yml
```

## Paso 8: Crear un commit con los cambios.

```bash
git commit -m "TP14: Integración del análisis automático de amenazas con Threagile"
```

## Paso 9: Subir los cambios a tu repositorio en GitHub.

```bash
git push origin main
```

## Paso 10: Verificar que el pipeline funciona correctamente.

En GitHub, abrí el repositorio y entrá en **Actions**. Seleccioná la ejecución correspondiente al commit del TP14 y verificá que el job **Threat Model Analysis** termine en verde. Al pie de la ejecución, descargá el artifact **threagile-report** y adjuntalo a la presentación.
