# TP13C - Integración de CI/CD, Kubernetes, Monitoreo y DAST con OWASP ZAP

## 1. Introducción

En este trabajo se integraron los contenidos desarrollados en los trabajos prácticos anteriores para construir un flujo de despliegue, monitoreo y análisis de seguridad de una aplicación web.

El objetivo fue llevar la aplicación de notas a un entorno Kubernetes local utilizando **k3d**, incorporar herramientas de monitoreo mediante **Prometheus, Grafana, Node Exporter y cAdvisor**, automatizar tareas mediante **GitHub Actions** y realizar un análisis dinámico de seguridad (**DAST**) utilizando **OWASP ZAP**.

A partir de esta integración se verificó el funcionamiento de la aplicación, la disponibilidad de sus servicios, la recolección de métricas y la ejecución automatizada de un análisis de seguridad.

Las capturas de pantalla correspondientes a las verificaciones realizadas se presentan como evidencia en el informe PDF del trabajo.

---

# 2. Entorno utilizado

El trabajo se realizó sobre un entorno Debian utilizando las siguientes herramientas:

* Docker
* Docker Compose
* Kubernetes
* k3d
* Helm
* Git
* GitHub
* GitHub Actions
* Docker Hub
* Prometheus
* Grafana
* Node Exporter
* cAdvisor
* OWASP ZAP

La aplicación utilizada corresponde al proyecto desarrollado en los trabajos prácticos anteriores y contiene:

* Frontend web.
* Backend.
* Base de datos PostgreSQL.

---

# 3. Organización del proyecto

Para el desarrollo del TP13C se reutilizaron los componentes realizados en los trabajos anteriores.

Las principales partes utilizadas fueron:

```text
guia-06/
└── app/
    ├── backend/
    └── frontend/

guia-08/
└── k8s/
    └── monitoring/

guia-09/
└── k8s/
    └── base/

guia-13/
├── k8s/
│   └── 04-zap-job.yaml
├── reportes/
│   ├── zap-k8s-report.html
│   └── zap-k8s-report.json
├── scripts/
│   ├── extract-zap-reports.sh
│   └── verificar-tp13c.sh
└── zap.yaml

scripts/
├── build-and-deploy.sh
└── create-cluster.sh

.github/
└── workflows/
    └── autoscan.yml
```

---

# 4. Sprint 1 - Kubernetes con k3d

## 4.1 Creación del clúster

Se creó un clúster Kubernetes local mediante **k3d**.

El entorno quedó compuesto por:

* 1 nodo servidor.
* 2 nodos agentes.

Se verificó que los tres nodos se encontraran en estado `Ready`.

El uso de k3d permitió disponer de un entorno Kubernetes local sobre Docker sin necesidad de utilizar infraestructura externa.

---

## 4.2 Despliegue de la aplicación

Una vez creado el clúster se desplegaron los componentes de la aplicación utilizando los manifiestos Kubernetes disponibles en el proyecto.

Se desplegaron:

* Frontend.
* Backend.
* PostgreSQL.
* Configuraciones necesarias para la aplicación.

También se configuraron los servicios correspondientes para permitir la comunicación entre los componentes.

---

## 4.3 Ingress

Para permitir el acceso externo a la aplicación se utilizó **NGINX Ingress Controller**, instalado mediante Helm.

El acceso local quedó configurado mediante el puerto:

```text
127.0.0.1:18080
```

y utilizando el hostname:

```text
notes.local
```

De esta manera fue posible acceder a la aplicación desde el entorno local a través del Ingress.

---

# 5. Sprint 2 - Monitoreo

## 5.1 Prometheus

Se incorporó **Prometheus** para la recolección y consulta de métricas del entorno.

El backend de la aplicación dispone además del endpoint:

```text
/metrics
```

permitiendo exponer métricas para que Prometheus pueda recolectarlas.

Se verificó que Prometheus pudiera consultar correctamente los endpoints configurados.

---

## 5.2 Grafana

Se desplegó **Grafana** como herramienta de visualización de las métricas recolectadas por Prometheus.

Se configuró Prometheus como fuente de datos y se verificó el acceso al servicio.

El dashboard permitió visualizar información relacionada con el estado y funcionamiento del entorno Kubernetes.

Las capturas del dashboard utilizado se incluyen como evidencia en el PDF del trabajo.

---

## 5.3 Node Exporter

Se incorporó **Node Exporter** para obtener métricas relacionadas con los nodos del entorno.

Esto permitió disponer de información sobre recursos y estado de los nodos utilizados por Kubernetes.

---

## 5.4 cAdvisor

También se incorporó **cAdvisor** para obtener métricas relacionadas con los contenedores.

Durante la implementación fue necesario adaptar su configuración para el entorno k3s utilizado por k3d.

Se configuró el acceso al socket de containerd:

```text
/run/k3s/containerd/containerd.sock
```

y se ajustó el contenedor para disponer de los permisos necesarios para realizar la recolección de métricas.

También se incorporó la configuración necesaria para aumentar el límite de archivos abiertos.

Con estas modificaciones cAdvisor pudo funcionar correctamente dentro del entorno utilizado.

---

# 6. Verificación del monitoreo

Una vez desplegados los componentes se verificó el funcionamiento general del sistema de monitoreo.

Se comprobaron:

* Estado de Prometheus.
* Estado de Grafana.
* Estado de Node Exporter.
* Estado de cAdvisor.
* Endpoint `/metrics` del backend.
* Targets de Prometheus.

Los targets configurados quedaron disponibles y en estado operativo.

La evidencia visual de Grafana y de las verificaciones realizadas se encuentra incluida en el PDF del trabajo.

---

# 7. Sprint 3 - GitHub Actions

## 7.1 Pipeline CI/CD

Se implementó un workflow de GitHub Actions en:

```text
.github/workflows/autoscan.yml
```

El workflow permite automatizar diferentes etapas del proceso.

La ejecución quedó organizada en cuatro jobs principales:

```text
lint
  ↓
test
  ↓
build_push

lint + test
      ↓
     zap
```

---

## 7.2 Lint y validaciones

El job `lint` realiza validaciones básicas del código.

Se verifica:

* Compilación de Python.
* Sintaxis de los scripts Bash.

La validación se realiza mediante comandos como:

```bash
python -m compileall
bash -n
```

Esto permite detectar errores básicos antes de continuar con las siguientes etapas del pipeline.

---

# 8. Construcción de imágenes

El job `test` realiza la construcción de las imágenes Docker de la aplicación como prueba previa al proceso de publicación.

Se construyen las imágenes correspondientes al:

* Backend.
* Frontend.

Esto permite comprobar que los Dockerfiles y los contextos de construcción sean válidos.

---

# 9. Publicación en Docker Hub

El job `build_push` se ejecuta en los eventos de `push` y realiza la publicación de las imágenes en Docker Hub.

Para evitar exponer credenciales dentro del repositorio se utilizaron secretos de GitHub Actions:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

Estos secretos se utilizaron mediante:

```yaml
${{ secrets.DOCKERHUB_USERNAME }}
${{ secrets.DOCKERHUB_TOKEN }}
```

Las imágenes se publican utilizando el SHA del commit como tag, permitiendo identificar de manera precisa la versión generada.

---

# 10. Sprint 4 - OWASP ZAP

## 10.1 Objetivo del análisis

Se incorporó **OWASP ZAP** para realizar un análisis dinámico de seguridad de la aplicación.

El análisis se ejecuta contra la aplicación desplegada dentro del clúster Kubernetes creado durante el workflow.

El objetivo fue automatizar un análisis DAST dentro del pipeline de CI/CD.

---

## 10.2 Configuración de ZAP

La configuración utilizada se encuentra en:

```text
guia-13/zap.yaml
```

Esta configuración define el comportamiento de la ejecución de ZAP.

Entre las tareas realizadas se encuentran:

* Spider.
* Spider Ajax.
* Espera del análisis pasivo.
* Active Scan.
* Generación de reportes.

El análisis permite detectar posibles problemas de seguridad presentes en los endpoints accesibles de la aplicación.

---

# 11. Job Kubernetes para ZAP

La ejecución de ZAP dentro de Kubernetes se definió mediante:

```text
guia-13/k8s/04-zap-job.yaml
```

El Job utiliza la imagen oficial de ZAP y ejecuta el análisis contra la aplicación desplegada.

El resultado del análisis se almacena dentro del volumen destinado a los reportes:

```text
zap-reports
```

El volumen se utiliza mediante un PVC denominado:

```text
zap-reports
```

El almacenamiento persistente permitió conservar los resultados del análisis para su posterior extracción.

---

# 12. Integración de ZAP en GitHub Actions

El job `zap` del workflow realiza las siguientes tareas:

1. Descarga el código del repositorio.
2. Instala k3d.
3. Crea un clúster Kubernetes temporal.
4. Despliega la aplicación.
5. Ejecuta el Job de ZAP.
6. Espera la finalización del análisis.
7. Extrae los reportes.
8. Publica los reportes como artifacts de GitHub Actions.

La ejecución utiliza un clúster temporal dentro del runner de GitHub Actions.

Esto permite que el análisis DAST se ejecute automáticamente sin depender del clúster local utilizado durante las pruebas manuales.

---

# 13. Extracción de reportes

Para recuperar los resultados del análisis se desarrolló el script:

```text
guia-13/scripts/extract-zap-reports.sh
```

Este script permite extraer los archivos generados por ZAP y colocarlos en:

```text
guia-13/reportes/
```

Los reportes generados son:

```text
zap-k8s-report.html
zap-k8s-report.json
```

El formato HTML permite consultar los resultados de manera visual, mientras que el JSON permite conservar la información estructurada del análisis.

---

# 14. Resultados del análisis DAST

El análisis realizado con OWASP ZAP finalizó correctamente.

Resultado obtenido:

| Nivel         | Cantidad |
| ------------- | -------: |
| High          |        0 |
| Medium        |        3 |
| Low           |        2 |
| Informational |        1 |

El resultado más importante es que **no se detectaron vulnerabilidades de nivel High**.

Se obtuvieron tres alertas de nivel Medium, dos de nivel Low y una informativa.

Los resultados completos se encuentran almacenados en:

```text
guia-13/reportes/zap-k8s-report.html
guia-13/reportes/zap-k8s-report.json
```

Las capturas correspondientes a las alertas y al resultado final de ZAP se presentan en el PDF como evidencia.

---

# 15. Script de verificación

Se desarrolló el script:

```text
guia-13/scripts/verificar-tp13c.sh
```

Su objetivo es realizar verificaciones del entorno y facilitar la comprobación final del TP13C.

Entre las verificaciones realizadas se contemplan:

* Estado de los nodos Kubernetes.
* Estado de los componentes desplegados.
* Servicios.
* Recursos relacionados con monitoreo.
* Estado de los componentes principales de la aplicación.
* Estado del Job de ZAP.
* Reportes generados.

De esta manera se dispone de una comprobación reproducible del estado general del trabajo.

---

# 16. Verificación final del pipeline

La ejecución final de GitHub Actions correspondió al workflow:

```text
TP13C CI CD and ZAP
```

Run:

```text
34370857999
```

La ejecución finalizó correctamente.

Los cuatro jobs principales quedaron en estado exitoso:

```text
✓ lint
✓ test
✓ build_push
✓ zap
```

El workflow también generó los artifacts correspondientes, incluyendo:

```text
zap-kubernetes-reports
```

Este artifact contiene los reportes generados durante el análisis de seguridad.

---

# 17. Estado final del repositorio

El repositorio utilizado para el TP13C es:

```text
leandroyh456/trabajo-13-c
```

La rama principal utilizada es:

```text
main
```

El trabajo quedó sincronizado con el repositorio remoto y el árbol de trabajo local quedó limpio.

El commit principal correspondiente a la finalización del TP13C fue:

```text
d167531 Completar TP13C con monitoreo y DAST
```

---

# 18. Resultados obtenidos

La integración realizada permitió cumplir con los principales objetivos planteados para el TP13C.

Se logró:

* Crear y utilizar un clúster Kubernetes local mediante k3d.
* Desplegar la aplicación y PostgreSQL.
* Configurar el acceso mediante NGINX Ingress.
* Incorporar Prometheus para la recolección de métricas.
* Incorporar Grafana para la visualización.
* Incorporar Node Exporter para métricas de los nodos.
* Incorporar cAdvisor para métricas de los contenedores.
* Adaptar cAdvisor al entorno k3d/k3s utilizado.
* Automatizar validaciones mediante GitHub Actions.
* Construir las imágenes Docker.
* Publicar las imágenes en Docker Hub.
* Integrar OWASP ZAP como análisis DAST.
* Generar y conservar reportes HTML y JSON.
* Ejecutar el análisis de seguridad dentro de GitHub Actions.
* Obtener una ejecución final exitosa de todos los jobs del pipeline.

El resultado final demuestra la integración entre **contenedorización, Kubernetes, monitoreo, CI/CD y seguridad**, utilizando herramientas que fueron incorporadas progresivamente durante los trabajos prácticos anteriores.

---

