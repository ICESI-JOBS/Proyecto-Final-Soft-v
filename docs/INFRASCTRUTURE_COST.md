# Costos de Infraestructura para ICESI-JOBS

Este documento describe los principales costos de infraestructura derivados del despliegue y operación del proyecto E-Commerce MicroServices en Microsoft Azure, gestionado como infraestructura como código con Terraform.

## 1. Resumen de la Infraestructura

La infraestructura está compuesta por los siguientes recursos principales:
- Grupo de recursos (Resource Group)
- Red virtual y subredes (Azure Virtual Network y Subnet)
- Kubernetes Cluster (Azure Kubernetes Service - AKS)
- Workspace de Log Analytics (para monitoreo)
- Recursos de almacenamiento (backend remoto para Terraform)
- Módulos reutilizables para red, Kubernetes y monitoreo

Cada entorno (`dev`, `stage`, `prod`) define su propio número de nodos AKS y tamaño de máquina virtual, personalizados según el ambiente ([ver `infra/envs/<env>/variables.tf`](../infra/envs/)).

## 2. Principales Componentes y Estimación de Costos

| Recurso                     | Características principales         | Variables asociadas           | Consideraciones de costo                           |
|-----------------------------|------------------------------------|-------------------------------|---------------------------------------------------|
| **Azure Kubernetes Service** | # de nodos, tipo de VM             | `node_count`, `vm_size`       | El rubro más alto, depende de cantidad y tipo     |
| **Red Virtual/Subnets**     | Espacio de direcciones dedicado    | `vnet_address_space`, etc     | Usualmente bajo costo, depende del tránsito       |
| **Log Analytics Workspace** | Integración con AKS para monitoreo | -                             | Costos dependen de logs almacenados y retención   |
| **Storage Account (tfstate)**| Almacenamiento remoto para Terraform| -                            | Generalmente bajo, por cantidad de archivos/TB    |

#### Ejemplo de Parámetros en Producción
- `node_count`: 2
- `vm_size`: `Standard_B4ms`
- Región: `eastus`
Estos valores pueden encontrarse en [infra/envs/prod/variables.tf](../infra/envs/prod/variables.tf).

## 3. Factores que afectan el costo

- **Cantidad de nodos en AKS**: Más nodos incrementan el costo.
- **Tipo de VM (`vm_size`)**: Máquinas más grandes (+vCPU, +RAM) son considerablemente más costosas.
- **Almacenamiento de logs**: Puede crecer con la retención y volumen de eventos.
- **Ambiente (dev/stage/prod)**: Cada ambiente puede estar activo en paralelo; costos crecen proporcionalmente.

## 4. Optimización y Control de Costos

- Usa entornos de desarrollo con nodos y VMs más pequeños.
- Destruye recursos cuando no estén en uso: 

    ```sh
    terraform destroy
    ```

- Monitorea el uso de logs y ajusta la retención de datos.
- Consulta las calculadoras de Azure para estimar precios actuales según configuración ([Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)).

## 5. Análisis de Costos con FinOps

Según el último reporte de FinOps (`finops-analysis-20251201-084840.json`), se ha realizado un análisis de costos para el entorno de desarrollo (`icesijobs-dev-rg`) con los siguientes resultados:

| Métrica                | Valor (unidades) |
|------------------------|------------------|
| **Costo Total Actual** | 100              |
| Desglose - AKS         | 100              |
| **Ahorro Potencial**   | 54               |
| **Costo Optimizado**   | 46               |

Estos datos, generados el 2025-12-01, indican que la mayor parte del costo se concentra en Azure Kubernetes Service (AKS). Se ha identificado un potencial de ahorro significativo, lo que sugiere que se pueden aplicar optimizaciones para reducir los costos operativos en el entorno de desarrollo.


## 6. Visualización de Costos

A continuación se incluyen imágenes tomadas desde el portal de Azure (ubicadas en `/docs/`):

- ![Ejemplo de Resumen de Costos - Azure](Costos%20Azure.jpeg)

- ![Detalle de Costos de Infraestructura](Costos%20Azure%202.jpeg)

## 6. Referencias y Enlaces Útiles

- [Documentación Infraestructura](./INFRASTRUCTURE_PROJECT.md)
- [Azure Kubernetes Service Pricing](https://azure.microsoft.com/en-us/pricing/details/kubernetes-service/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)

---

> **Nota**: Los valores y costos exactos pueden variar mes a mes y dependen también del uso concreto y tamaño de cada recurso. Es recomendable validar los costos reales desde el Portal de Azure.
