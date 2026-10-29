## TP18 — Gestión Centralizada de Vulnerabilidades con OWASP DefectDojo 
 
Integración de **OWASP DefectDojo Community Edition** para consolidar, desduplicar y auditar los hallazgos de ciberseguridad provenientes de OWASP ZAP (DAST), Threagile (Threat Modeling), Semgrep (SAST), Trivy (SCA/Container/IaC) y Gitleaks (Secret Scanning). 
 
### Arquitectura de Integración en 4 Fases 
 
Fase;Herramienta;Función;Mecanismo 
Fase 1;Docker Buildx;Compilación inmutable;Exporta app-image.tar 
Fase 2;OWASP ZAP / Threagile / Semgrep / Trivy / Gitleaks;Auditoría multidominio;Genera reportes JSON/XML estructurados 
Fase 3;OWASP DefectDojo;Vulnerability Management;Ingestión vía API v2 y deduplicación 
Fase 4;Helm & K8s;Despliegue a producción;Release verificado en Kubernetes 

 

---- Visualizacion en Word como tabla --- 

Fase 

Herramienta 

Función 

Mecanismo 

1 

Docker Buildx 

Compilación inmutable 

Exporta app-image.tar 

2 

OWASP ZAP / Threagile / Semgrep / Trivy / Gitleaks 

Auditoría multidominio 

Genera reportes JSON/XML estructurados 

3 

OWASP DefectDojo 

Vulnerability Management 

Ingestión vía API v2 y deduplicación 

4 

Helm & K8s 

Despliegue a producción 

Release verificado en Kubernetes 

 

 

Comandos de Verificación Local 

# Otorgar permisos y ejecutar script de carga a DefectDojo 
chmod +x scripts/verificar-defectdojo.sh 
DEFECTDOJO_URL="http://localhost:8080" DEFECTDOJO_API_KEY="tu_token" ./scripts/verificar-defectdojo.sh 
