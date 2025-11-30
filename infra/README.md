## Infraestructura con Terraform (Azure)

Este directorio contiene la infraestructura como código para el proyecto del ecommerce basado en microservicios, desplegado sobre Microsoft Azure usando Terraform.

El objetivo de esta configuración es:

- Proveer una base estructurada y modular de Terraform.
- Crear recursos centrales de infraestructura en Azure (Resource Group, Virtual Network, un clúster AKS y Monitoreo).
- Permitir diferenciar entornos (dev, stage, prod) usando workspaces y carpetas dedicadas.
- Facilitar la gestión y el despliegue a través de un flujo de trabajo claro.

## Estructura

La carpeta `infra/` ha evolucionado a una estructura modular y basada en entornos para mejorar la reutilización y la separación de responsabilidades:

```
infra/
├── envs/
│   └── dev/
│       ├── main.tf              # Llama a los módulos con valores para el entorno 'dev'
│       ├── variables.tf         # Variables específicas de 'dev'
│       ├── outputs.tf           # Salidas del entorno 'dev'
│       └── .terraform.lock.hcl
│
├── modules/
│   ├── aks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── monitoring/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── .gitignore
├── README.md                    # Esta documentación
└── ... (otros archivos raíz que pueden ser legacy o de configuración global)
```

- **`envs/`**: Contiene una subcarpeta por cada entorno (ej. `dev`, `stage`, `prod`). Cada una tiene su propio `main.tf` que consume los módulos del directorio `modules` para construir la infraestructura de ese entorno específico.
- **`modules/`**: Contiene módulos de Terraform reutilizables. Cada módulo encapsula una pieza lógica de la infraestructura:
    - **`aks`**: Define el clúster de Azure Kubernetes Service.
    - **`network`**: Define la Virtual Network, subredes y otros componentes de red.
    - **`monitoring`**: Define los recursos de monitoreo, como Log Analytics Workspace.

## Historias de Usuario Cubiertas

1.  **Inicializar un proyecto Terraform estructurado**: Se cumple mediante la organización en módulos y entornos, lo que permite una gestión limpia y escalable.
2.  **Modularización de la infraestructura**: Se ha implementado extrayendo la lógica de `AKS`, `network` y `monitoring` en módulos reutilizables, permitiendo que cada pieza evolucione de forma independiente.
3.  **Backend para estado de Terraform**: El backend sigue siendo local dentro de cada entorno (`envs/dev/terraform.tfstate`), pero está preparado para migrar a un backend remoto (Azure Storage) para trabajo en equipo.
4.  **Multi-ambiente**: Implementado a través de directorios dedicados en `envs/`, lo que proporciona un aislamiento mucho más robusto que el uso de variables. Cada entorno tiene su propio estado y configuración.

## Recursos que se crean (por entorno)

La infraestructura definida en el entorno `dev` crea:

- Un **Resource Group**.
- Una **Virtual Network** con sus subredes (gracias al módulo `network`).
- Un **clúster AKS (Azure Kubernetes Service)** (gracias al módulo `aks`).
- Un **Log Analytics Workspace** para monitoreo (gracias al módulo `monitoring`).

## Prerrequisitos

- Terraform ≥ 1.6.0
- Azure CLI instalado y autenticado:
  ```bash
  az login
  az account show
  ```
- Permisos suficientes en la suscripción de Azure para crear los recursos mencionados.

## Flujo de uso recomendado

El flujo de trabajo ahora se realiza **dentro del directorio del entorno** que se desea gestionar.

1.  **Entrar a la carpeta del entorno `dev`**:
    ```bash
    cd infra/envs/dev
    ```

2.  **Inicializar Terraform**:
    Esto descargará los proveedores y configurará los módulos.
    ```bash
    terraform init
    ```

3.  **Ver el plan de ejecución**:
    Revisa qué cambios se aplicarán en la infraestructura.
    ```bash
    terraform plan
    ```

4.  **Aplicar los cambios**:
    Crea o actualiza la infraestructura en Azure.
    ```bash
    terraform apply --auto-approve
    ```

5.  **Obtener credenciales del clúster AKS**:
    Usa el output de Terraform para configurar `kubectl`.
    ```bash
    terraform output -raw aks_kube_config > ~/.kube/config_dev
    export KUBECONFIG=~/.kube/config_dev
    kubectl get nodes
    ```
    *Nota: El comando exacto puede variar según la configuración de `outputs.tf`.*

## Seguridad

- **No guardar secretos**: Evita commitear información sensible. Utiliza variables de entorno o Azure Key Vault.
- **Estado remoto**: Para equipos, es crucial migrar el backend a uno remoto como Azure Storage para evitar conflictos y mantener un estado único.
- **Mínimo privilegio**: Asegúrate de que las credenciales usadas por Terraform tengan solo los permisos necesarios.

## Limpieza

Para destruir toda la infraestructura de un entorno, ejecuta el comando desde el directorio correspondiente:

```bash
cd infra/envs/dev
terraform destroy --auto-approve
```

## Próximos pasos

- **Migrar backend local a remoto**: Implementar un backend en Azure Storage para habilitar la colaboración y la ejecución en pipelines de CI/CD.
- **Añadir más entornos**: Crear carpetas `stage` y `prod` en el directorio `envs`.
- **Expandir módulos**:
    - **`database`**: Para gestionar bases de datos como Azure SQL o PostgreSQL.
    - **`security`**: Para Network Security Groups (NSGs), Firewalls, y políticas de seguridad.
- **Integración con CI/CD**: Automatizar los flujos de `plan` y `apply` usando GitHub Actions, validando el código en cada Pull Request.
