# Infraestructura como Código con Terraform

Este directorio contiene el código de Terraform para aprovisionar y gestionar toda la infraestructura del proyecto en Microsoft Azure.

## Resumen de la Arquitectura

La infraestructura está diseñada para ser modular, escalable y gestionable a través de diferentes entornos, siguiendo las mejores prácticas de IaC (Infrastructure as Code).

### Características Principales

- **Gestión con Terraform**: Toda la infraestructura (redes, clústeres de Kubernetes, monitoreo, etc.) se define como código utilizando Terraform, lo que garantiza la reproducibilidad y la automatización.
- **Estructura Modular**: La infraestructura se divide en módulos reutilizables (`network`, `aks`, `monitoring`) ubicados en el directorio `modules/`. Esto permite una gestión más sencilla y un código más limpio.
- **Soporte para Múltiples Entornos**: La configuración soporta distintos entornos como `dev`, `stage` y `prod`. Cada entorno está aislado en su propio directorio dentro de `envs/`, lo que permite configuraciones personalizadas y estados independientes.
- **Backend Remoto**: Se utiliza un backend remoto (Azure Storage Account) para almacenar el estado de Terraform (`.tfstate`). Esto es crucial para el trabajo en equipo, ya que evita conflictos de estado y garantiza que todos los miembros del equipo y los pipelines de CI/CD trabajen sobre la misma versión de la infraestructura.
- **Documentación Visual**: La arquitectura de la infraestructura está documentada a través de diagramas para facilitar la comprensión de su diseño y componentes.

## Estructura de Archivos

```
infra/
├── envs/
│   ├── dev/
│   │   ├── main.tf              # Configuración principal para 'dev'
│   │   ├── variables.tf         # Variables para 'dev'
│   │   └── outputs.tf           # Salidas de 'dev'
│   ├── stage/
│   └── prod/
│
├── modules/
│   ├── aks/                     # Módulo para Azure Kubernetes Service
│   ├── network/                 # Módulo para la red virtual y subredes
│   └── monitoring/              # Módulo para recursos de monitoreo
│
├── main.tf                      # Configuración raíz (puede definir el backend)
├── variables.tf                 # Variables globales
├── providers.tf                 # Definición de proveedores (AzureRM)
└── README.md                    # Esta documentación
```

## Diagrama de Arquitectura para Terraform

![alt text](<Arquitecture_Diagram_Terraform.png>)

## Requisitos Previos

- Terraform v1.6.0 o superior
- Azure CLI
- Estar autenticado en Azure (`az login`) con permisos para crear los recursos.

## Cómo Empezar

El flujo de trabajo se realiza desde el directorio del entorno que se desea gestionar.

1.  **Navegar al directorio del entorno**:
    ```sh
    cd envs/dev
    ```

2.  **Inicializar Terraform**:
    Descarga los proveedores y configura el backend remoto.
    ```sh
    terraform init
    ```

3.  **Planificar los cambios**:
    Muestra los cambios que se aplicarán en la infraestructura sin ejecutarlos.
    ```sh
    terraform plan
    ```

4.  **Aplicar los cambios**:
    Crea o actualiza los recursos en Azure.
    ```sh
    terraform apply
    ```

## Destruir la Infraestructura

Para eliminar todos los recursos de un entorno y evitar costos, ejecuta el siguiente comando desde el directorio del entorno correspondiente:

```sh
cd envs/dev
terraform destroy
```