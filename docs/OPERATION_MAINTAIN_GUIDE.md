# Guía de Operación y Mantenimiento

**Proyecto:** ICESI-JOBS/Proyecto-Final-Soft-v

Este documento recopila las mejores prácticas y procedimientos para la operación, monitoreo y mantenimiento seguro de la infraestructura y los servicios de este proyecto.

---

## 1. Operación Diaria

### 1.1. Acceso y monitoreo del estado del clúster AKS

- Utiliza Azure Portal o la CLI de Azure para revisar el estado del clúster:
  ```sh
  az aks get-credentials --resource-group <nombre_rg> --name <nombre_aks>
  kubectl get nodes
  kubectl get pods -A
  ```
- Verifica el estado de los recursos y posibles problemas con:
  ```sh
  kubectl describe pod <nombre_pod> -n <namespace>
  kubectl logs <nombre_pod> -n <namespace>
  ```

### 1.2. Despliegue de nuevas versiones

- Los despliegues se realizan mediante pipelines de CI/CD (GitHub Actions).
- Para ambientes controlados (stage/prod) activa manualmente los workflows desde la UI de GitHub.
- Para subir imágenes nuevas a AKS asegúrate de que los tags de versión se apliquen correctamente (ver CI/CD).

### 1.3. Gestión de recursos en Azure

- Monitorea el consumo de recursos (CPU, memoria, discos) desde Azure Portal o con herramientas como `kubectl top`.
- Supervisa el uso de almacenamiento de Log Analytics, recursos de red y el almacenamiento para el estado de Terraform.

---

## 2. Mantenimiento de la Infraestructura

### 2.1. Cambios de infraestructura (Terraform)

- Los cambios en recursos de red, clusters, o monitoring deben realizarse vía Terraform.
  ```sh
  cd infra/envs/<dev|stage|prod>
  terraform plan   # Revisa los cambios propuestos
  terraform apply  # Aplica los cambios
  ```
- Documenta cada cambio significativo.

### 2.2. Respaldo y restauración del estado de infraestructura

- El archivo `terraform.tfstate` se almacena en un Azure Storage Account configurado como backend remoto.
- Si es necesario, restaura el estado descargando la versión deseada desde el portal de Azure.

### 2.3. Destrucción segura de entornos

- Para liberar recursos y evitar costos innecesarios (por ejemplo, en entornos dev/stage):
  ```sh
  terraform destroy
  ```

---

## 3. Seguridad Operacional

- Requiere autenticación en Azure para cualquier operación administrativa.
- Usa el principio de privilegios mínimos para cuentas y claves de acceso.
- Mantén los secretos (tokens, claves) en los gestores de CI/CD o en Azure Key Vault.

---

## 4. Manejo de incidentes

### 4.1. Identificación y diagnóstico

- Utiliza los comandos de logs y describe de Kubernetes.
- Consulta los dashboards de Azure Monitor para eventos críticos o sobrecargas.

### 4.2. Reemplazo de pods/servicios defectuosos

- Elimina pods problemáticos para que Kubernetes los reprograme:
  ```sh
  kubectl delete pod <nombre_pod> -n <namespace>
  ```
- Restaura el servicio mediante despliegue de la última versión estable si es necesario.

---

## 5. Actualización y parches

- Actualiza las dependencias de los microservicios como parte del ciclo de CI.
- Para el plano de control AKS y los nodepools, revisa periódicamente las notas de Azure y realiza upgrades fuera de horarios productivos.
- Mantén actualizado Terraform en las versiones soportadas.

---

## 6. Buenas prácticas adicionales

- Mantén la documentación de infraestructura actualizada (ver `/docs/INFRASTRUCTURE_PROJECT.md`).
- Haz uso de etiquetas y convención de ramas según la guía de branching.
- Depura y limpia recursos no utilizados con regularidad.

---

## 7. Recursos

- [Documentación Infraestructura del Proyecto](./INFRASTRUCTURE_PROJECT.md)
- [Documentación CI/CD](./CI_CD_DOCUMENTATION.md)
- [Guía de branching y flujos de desarrollo](./BRANCHING_STRATEGIC.md)
- [Azure AKS Docs](https://docs.microsoft.com/es-es/azure/aks/)
- [Terraform Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

**Ante dudas o incidentes mayores, contactar al responsable de DevOps del equipo.**