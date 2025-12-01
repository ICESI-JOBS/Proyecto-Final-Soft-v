# Plan de Rollback

Este documento describe el procedimiento para revertir un despliegue en el entorno de Producción si se detecta un incidente crítico después de una nueva release.

## 1. Criterios para Iniciar un Rollback

Un rollback debe ser considerado si una nueva versión causa uno o más de los siguientes problemas críticos en producción:

-   **Error Crítico Generalizado:** La funcionalidad principal de la aplicación no está disponible para una gran cantidad de usuarios.
-   **Corrupción o Pérdida de Datos:** La nueva versión está causando inconsistencias o pérdida de información.
-   **Degradación Severa del Rendimiento:** La aplicación es extremadamente lenta hasta el punto de ser inutilizable.
-   **Incidente de Seguridad:** La nueva versión ha introducido una vulnerabilidad de seguridad crítica.

La decisión de iniciar un rollback será tomada por el líder técnico en conjunto con el Product Owner.

## 2. Estrategia de Rollback

Nuestra infraestructura en Kubernetes nos permite realizar rollbacks de manera rápida y controlada. La estrategia principal se basa en el historial de revisiones que Kubernetes mantiene para cada `Deployment`.

### Procedimiento Técnico:

1.  **Identificar el Deployment Afectado:**
    -   Primero, identifica el nombre del `Deployment` del microservicio que está fallando (e.g., `user-service`, `product-service`).

2.  **Revisar el Historial de Despliegues:**
    -   Se puede ver el historial de `rollouts` para un deployment específico con el siguiente comando:
      ```bash
      kubectl rollout history deployment/<nombre-del-deployment> -n <namespace>
      ```

3.  **Ejecutar el Rollback a la Versión Anterior:**
    -   Para revertir el deployment a la versión estable anterior (la penúltima revisión), se utiliza el comando `undo`:
      ```bash
      kubectl rollout undo deployment/<nombre-del-deployment> -n <namespace>
      ```
    -   Este comando le indica a Kubernetes que reemplace los Pods de la versión actual con los de la versión anterior, de forma controlada y gradual.

4.  **Verificar el Estado del Rollback:**
    -   Monitorea el estado del `undo` para asegurarte de que los nuevos Pods se levanten correctamente y los antiguos se terminen.
      ```bash
      kubectl rollout status deployment/<nombre-del-deployment> -n <namespace>
      ```

5.  **Validar la Aplicación:**
    -   Una vez que el rollback se ha completado, el equipo de QA y/o el líder técnico deben verificar que la aplicación ha vuelto a su estado estable y que el problema crítico ha sido resuelto.

## 3. Plan de Comunicación

La comunicación clara es crucial durante un incidente.

-   **Interna:**
    -   El líder técnico notificará inmediatamente al equipo de desarrollo, DevOps y al Product Owner sobre la decisión de realizar un rollback.
    -   Se creará un canal de comunicación dedicado (e.g., en Slack o Teams) para coordinar el esfuerzo.
-   **Externa (si aplica):**
    -   Si el incidente tiene un impacto visible para el cliente, el equipo de soporte o comunicación actualizará la página de estado del sistema para informar a los usuarios sobre el problema y las medidas que se están tomando.

## 4. Post-Rollback (Análisis Post-Mortem)

Después de que la situación se haya estabilizado:

1.  **Preservar la Evidencia:** No eliminar la versión fallida. La imagen de Docker y el código asociado deben ser preservados para su análisis. La rama `release` que causó el problema no debe ser eliminada.
2.  **Análisis de Causa Raíz (RCA):** Se programará una reunión post-mortem para investigar la causa raíz del fallo.
3.  **Crear Plan de Acción:** Se documentarán las lecciones aprendidas y se crearán acciones concretas para prevenir que un problema similar ocurra en el futuro (e.g., mejorar las pruebas, ajustar el monitoreo, etc.).
