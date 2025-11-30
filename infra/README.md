## Infraestructura con Terraform (Azure)

Este directorio contiene la infraestructura como código para el proyecto del ecommerce basado en microservicios, desplegado sobre Microsoft Azure usando Terraform.

El objetivo de esta configuración es:

- Proveer una base estructurada de Terraform (cumpliendo la HU de inicialización del proyecto).

- Crear recursos centrales de infraestructura en Azure (Resource Group, Virtual Network y un clúster AKS).

- Permitir diferenciar entornos (dev, stage, prod) usando variables.

- Dejar el proyecto listo para evolucionar hacia:

    - Backend remoto.

    - Módulos reutilizables.

    - Múltiples ambientes separados por carpetas.

## Estructura

Actualmente la carpeta infra/ tiene la siguiente estructura:

~~~

infra/

├── main.tf              # Declaración principal de recursos (RG, VNet, AKS)

├── providers.tf         # Configuración del proveedor Azurerm y backend local

├── variables.tf         # Variables de entrada (región, prefijo, entorno, tamaño de nodos)

├── outputs.tf           # Salidas (nombre RG, nombre AKS, comando para credenciales)

└── .terraform.lock.hcl  # Lockfile de Terraform (no editar manualmente)

~~~

## Nota: No hay todavía subcarpetas modules/ ni environments/. La separación de entornos se realiza por ahora mediante la variable env definida en variables.tf.

## Historias de Usuario Cubiertas

1. Inicializar un proyecto Terraform estructurado

Como ingeniero DevOps Quiero inicializar un proyecto Terraform estructurado Para gestionar la infraestructura de manera automatizada.

Esta HU se cumple porque:

Existe un main.tf que define recursos reales en Azure.

providers.tf establece:

La versión mínima de Terraform (>= 1.6.0).

El proveedor azurerm con versión fijada (~> 4.0).

Un backend (por ahora local).

variables.tf centraliza parámetros clave del despliegue.

El proyecto puede inicializarse con:

~~~

cd infra

terraform init

~~~

1. Preparación para modularización

Como desarrollador DevOps Quiero organizar la infraestructura en módulos Para que sea reusable, escalable y mantenible.

Actualmente, toda la infraestructura se declara en main.tf. Se utiliza un local.base\_name basado en project\_prefix + env, lo que facilita luego dividir esta lógica en módulos sin romper el nombre de los recursos.

Ejemplo (en main.tf):

~~~

Terraform

locals {

\# Nombre base para recursos

base\_name = "${var.project\_prefix}-${var.env}"

}

~~~

A partir de este base\_name se nombran:

~~~

Resource Group: ${local.base\_name}-rg

Virtual Network: ${local.base\_name}-vnet

~~~

(y el resto de recursos asociados en el archivo)

Esto permitirá más adelante extraer un módulo resource\_group, un módulo network y un módulo aks sin impactar la convención de nombres del proyecto.

1. Backend para estado de Terraform (actual: local, preparado para remoto)

Como ingeniero DevOps Quiero almacenar el estado de Terraform en un backend remoto Para asegurar consistencia entre equipos.

En providers.tf está definido un backend local:

~~~
Terraform

terraform {

required\_version = ">= 1.6.0"

required\_providers {

azurerm = {

source  = "hashicorp/azurerm"

version = "~> 4.0"

}

}

\# De momento usamos backend local.

\# Más adelante puede cambiarse a Azure Storage (backend remoto).

backend "local" {

path = "terraform.tfstate"

}

}

~~~

Esto cumple lo necesario para desarrollo local y documenta explícitamente la intención de cambiarlo luego a un backend remoto mediante Azure Storage.

1. Multi-ambiente usando variables (dev, stage, prod)

Como DevOps Quiero tener múltiples ambientes independientes en Terraform Para desplegar versiones aisladas del proyecto.

En variables.tf está definido:

~~~

variable "env" {

description = "Nombre del entorno (dev/stage/prod)"

type        = string

default     = "dev"

}

~~~

Y en main.tf se usa:

~~~

locals {

base\_name = "${var.project\_prefix}-${var.env}"

}

resource "azurerm\_resource\_group" "rg" {

name     = "${local.base\_name}-rg"

location = var.location

}

~~~

Esto permite la separación de entornos simplemente ejecutando:

~~~

terraform apply -var="env=dev"

terraform apply -var="env=stage"

terraform apply -var="env=prod"

~~~

## Recursos que se crean actualmente

La infraestructura definida crea:

- Un Resource Group.

- Una Virtual Network.

- Un cluster AKS (Azure Kubernetes Service) con:

    - RBAC habilitado.

    - Red avanzada configurada.

    - Node pool estándar.

Integración con red definida vía network\_profile.

#### Nota: En el main.tf existe un bloque ... que indica dónde se extiende la configuración del clúster y red en futuras entregas.

## Salidas (outputs)

En outputs.tf el proyecto expone:

~~~

Terraform

output "resource\_group\_name" {

description = "Nombre del resource group generado"

value       = azurerm\_resource\_group.rg.name

}

output "aks\_name" {

description = "Nombre del cluster AKS"

value       = azurerm\_kubernetes\_cluster.aks.name

}

output "aks\_kube\_config" {

description = "Comando para obtener credenciales del AKS"

value       = "az aks get-credentials --resource-group ${azurerm\_resource\_group.rg.name} --name ${azurerm\_kubernetes\_cluster.aks.name}"

}
~~~

Esto permite conectarse rápidamente al clúster:
~~~

Bash

terraform output aks\_kube\_config

~~~

Prerrequisitos

Terraform ≥ 1.6.0

Azure CLI instalado:

~~~

az login

az account show

~~~

Permisos en Azure para crear: Resource Groups, VNets y AKS clusters.

## Flujo de uso recomendado

Entrar a la carpeta infra:

~~~

cd infra

~~~

Inicializar:

~~~

terraform init

~~~

Ver el plan:

~~~

terraform plan \

- var="location=eastus" \
- var="project\_prefix=icesijobs" \
- var="env=dev"

~~~

Aplicar:

~~~

terraform apply \

- var="location=eastus" \
- var="project\_prefix=icesijobs" \
- var="env=dev"

~~~

Obtener credenciales del cluster AKS:

~~~

terraform output aks\_kube\_config

~~~

## Seguridad

Recomendaciones importantes:

- No guardar contraseñas o secretos en archivos .tf ni en Git.

- Usar Azure Key Vault o secretos de GitHub Actions.

- Restringir acceso a AKS y SSH (cuando se añadan NSGs).

- Dividir redes por subredes específicas en entornos productivos.

## Limpieza

Para destruir la infraestructura:

~~~

terraform destroy \

- var="location=eastus" \
- var="project\_prefix=icesijobs" \
- var="env=dev"

~~~

Próximos pasos (recomendado para mejorar la IaC)

Para evolucionar la infraestructura y continuar con las historias de usuario:

- Migrar backend local → Backend remoto con Azure Storage.

- Crear carpetas por entorno (environments/dev, stage, prod).

- Extraer la infraestructura a módulos reutilizables:

~~~
resource\_group

network

aks

~~~

- Añadir módulos como:

~~~

vm (para runners, SonarQube, etc.)

security (NSG, firewall)

observability (Log Analytics)

~~~

Integrar Terraform en un pipeline (GitHub Actions):

fmt, validate, plan, apply.
