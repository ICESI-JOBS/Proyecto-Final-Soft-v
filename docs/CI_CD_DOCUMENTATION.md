# Documentación de CI/CD

Este documento describe la arquitectura y el funcionamiento de los pipelines de Integración Continua (CI) y Despliegue Continuo (CD) del proyecto. El sistema principal utilizado es **GitHub Actions**.

## 1. Implementación de Pipelines de CI/CD

El proyecto utiliza un conjunto de workflows de GitHub Actions para automatizar la integración, el análisis de calidad y el despliegue de la aplicación. Los pipelines principales se encuentran en el directorio `.github/workflows/`:

- **`ci-cd.yml`**: Es el pipeline principal de CI. Se encarga de construir, probar, analizar la seguridad y desplegar en el ambiente de `dev`.
- **`ci-code-quality.yml`**: Este pipeline se dedica exclusivamente al análisis estático de código con SonarCloud.
- **`deploy-stage.yml`**: Pipeline para el despliegue manual en el entorno de `stage`.
- **`deploy-prod.yml`**: Pipeline para el despliegue manual y controlado en el entorno de `prod`.

Aunque existe un archivo `azure-pipelines.yml`, la lógica principal y más avanzada reside en GitHub Actions.

## 2. Ambientes Separados y Promoción Controlada

El sistema está configurado para gestionar tres entornos distintos: `dev`, `stage` y `prod`, garantizando un flujo de promoción controlado.

- **Entorno `dev` (Desarrollo)**:
    - **Activación**: Automática, con cada `push` a la rama `dev`.
    - **Lógica**: El workflow `ci-cd.yml` se ejecuta, compila, prueba, construye las imágenes Docker y las despliega en el namespace `icesi-dev` de AKS utilizando los manifiestos de la carpeta `k8s/`.

- **Entorno `stage` (Pruebas de Aceptación)**:
    - **Activación**: Manual. Un desarrollador debe ejecutar el workflow `deploy-stage.yml` desde la interfaz de GitHub Actions (`workflow_dispatch`).
    - **Lógica**: Este pipeline despliega las imágenes ya existentes en el namespace `icesi-stage` de AKS, utilizando la configuración del directorio `k8s-stage/`. Esto representa una **promoción controlada** desde `dev`.

- **Entorno `prod` (Producción)**:
    - **Activación**: Manual y con aprobación. Se activa ejecutando `deploy-prod.yml` (`workflow_dispatch`).
    - **Lógica**: Antes de ejecutarse, GitHub Actions requiere la **aprobación de revisores designados** (ver sección 7). Una vez aprobado, despliega la aplicación en el namespace `icesi-prod` de AKS usando los manifiestos de `k8s-prod/`.

## 3. Análisis Estático de Código (SonarQube)

Se utiliza **SonarCloud** (la versión SaaS de SonarQube) para el análisis estático de código, integrado a través del pipeline `ci-code-quality.yml`.

- **Activación**: Se ejecuta en cada `push` o `pull request` a las ramas `dev` y `main`.
- **Configuración**: Los parámetros del análisis están definidos en el archivo `sonar-project.properties`, que especifica la URL del host, la organización, las rutas de código fuente y de pruebas.
- **Proceso**: El pipeline compila el proyecto y luego invoca la acción `SonarSource/sonarcloud-github-action` para enviar el análisis a SonarCloud, utilizando un `SONAR_TOKEN` almacenado en los secrets del repositorio.

## 4. Escaneo de Vulnerabilidades en Contenedores (Trivy)

El escaneo de vulnerabilidades se realiza con **Trivy** como parte del pipeline principal `ci-cd.yml`.

- **Proceso**: Se ejecuta en el job `docker-build-and-push`, justo antes de construir las imágenes Docker.
- **Configuración**:
    - `scan-type: 'fs'`: Analiza el sistema de archivos (`filesystem`) en busca de vulnerabilidades.
    - `vuln-type: 'os,library'`: Busca vulnerabilidades tanto en las librerías del sistema operativo base de la imagen como en las librerías de la aplicación (ej. dependencias de Java).
    - `severity: 'CRITICAL,HIGH'`: Reporta únicamente las vulnerabilidades de severidad alta y crítica.
    - `exit-code: '0'`: El pipeline no falla si se encuentran vulnerabilidades, pero estas quedan registradas en los logs para su revisión.

## 5. Versionado Semántico Automático

**Se ha implementado una estrategia de versionado semántico automático** para las imágenes Docker, que se activa durante la ejecución del pipeline `ci-cd.yml`.

- **Herramienta**: Se utiliza la acción `mathieudutour/github-tag-action@v6.2` para automatizar la creación de versiones.

- **Flujo de Versionado**:
    - **En la rama `master`**:
        1.  Cuando se integra un cambio en `master`, la acción `github-tag-action` se activa.
        2.  Automáticamente crea un nuevo tag de Git incrementando la versión (por defecto, hace un `patch`, ej. de `v1.2.3` a `v1.2.4`).
        3.  Las imágenes Docker de todos los microservicios se construyen y se etiquetan con este nuevo número de versión (ej. `api-gateway:v1.2.4`).
        4.  Adicionalmente, también se les asigna el tag `:latest` para señalar la versión más reciente de producción.
    - **En la rama `dev`**:
        - Las imágenes Docker generadas desde la rama `dev` se etiquetan de forma estática como `dev` (ej. `api-gateway:dev`).

Este sistema asegura que cada despliegue que pasa por `master` tenga un número de versión único y trazable, mientras que el entorno de desarrollo utiliza una etiqueta flotante para la última versión en pruebas.

## 6. Notificaciones Automáticas para Fallos

El sistema de notificaciones ha sido mejorado para proporcionar alertas proactivas y detalladas en caso de fallo, utilizando una integración con **Slack**.

- **Herramienta**: Se utiliza la acción `slackapi/slack-github-action@v1.27.0`.
- **Activación**: Un paso de notificación se ejecuta al final de cada job en los pipelines principales (`ci-cd.yml`, `deploy-stage.yml`, `deploy-prod.yml`), pero solo si el job ha fallado (`if: failure()`).
- **Proceso**:
    1. Si un job falla, se activa el paso de notificación.
    2. Se envía un mensaje formateado a un canal de Slack preconfigurado.
    3. El mensaje contiene detalles clave sobre el fallo, como el repositorio, el workflow, el job, la rama y el autor del cambio, permitiendo una rápida identificación del problema.
- **Configuración**: La URL del webhook de Slack se gestiona de forma segura a través del secret `SLACK_WEBHOOK_URL` del repositorio.

Esta configuración reemplaza la dependencia exclusiva de las notificaciones por correo electrónico de GitHub, ofreciendo un sistema de alertas más inmediato y centralizado para el equipo de desarrollo.

## 7. Aprobaciones para Despliegues a Producción

**Sí, esta funcionalidad está implementada** utilizando la característica de **Entornos de GitHub**.

- **Configuración**: El workflow `deploy-prod.yml` está asociado al entorno `environment: prod`.
- **Mecanismo de control**: Dentro de la configuración del repositorio en GitHub (`Settings > Environments > prod`), se han añadido "Required reviewers".
- **Flujo**:
    1.  Un usuario inicia manualmente el pipeline de despliegue a producción.
    2.  El pipeline se detiene y entra en estado "Waiting".
    3.  GitHub notifica a los revisores designados.
    4.  El pipeline solo continuará su ejecución y realizará el despliegue si uno de los revisores aprueba la ejecución.

Este mecanismo garantiza que ningún despliegue a producción se realice sin la supervisión y aprobación explícita de una persona autorizada.
