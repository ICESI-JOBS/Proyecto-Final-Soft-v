# Documentación de Patrones de Diseño

Este documento describe los principales patrones de diseño arquitectónicos y de aplicación utilizados en este proyecto de microservicios. La estandarización de estos patrones es crucial para mantener un código cohesivo, escalable y mantenible.

## Patrones Arquitectónicos

Estos patrones definen la estructura general del sistema de microservicios y cómo interactúan entre ellos.

### 1. API Gateway

- **Descripción**: Es un único punto de entrada para todas las peticiones de los clientes. El API Gateway enruta las peticiones al microservicio correspondiente, puede agregar una capa de seguridad (autenticación/autorización), manejar la terminación SSL y realizar balanceo de carga. Esto simplifica el cliente y desacopla la arquitectura interna de los consumidores externos.
- **Implementación**: Se utiliza el módulo `api-gateway`. Este servicio está construido con **Spring Cloud Gateway** y actúa como el enrutador principal. También se integra con el Service Discovery para encontrar dinámicamente las instancias de los servicios.

### 2. Service Discovery (Descubrimiento de Servicios)

- **Descripción**: En una arquitectura de microservicios, las ubicaciones de red de las instancias de servicio cambian dinámicamente. El patrón de Service Discovery utiliza un registro central (Registry) donde cada servicio se registra al iniciar. Otros servicios y el API Gateway consultan este registro para encontrar la ubicación de los servicios que necesitan consumir.
- **Implementación**: Se utiliza el módulo `service-discovery`, que implementa un servidor **Netflix Eureka**. Todos los demás microservicios (como `user-service`, `product-service`, etc.) están configurados como clientes Eureka, registrándose en este servidor al arrancar.

### 3. Externalized Configuration (Configuración Externalizada)

- **Descripción**: Este patrón consiste en externalizar la configuración de la aplicación (como credenciales de base de datos, URLs de otros servicios, etc.) fuera del código fuente. Esto permite gestionar la configuración de todos los microservicios desde un lugar centralizado y modificarla sin necesidad de reconstruir o redesplegar los servicios.
- **Implementación**: El módulo `cloud-config` actúa como un servidor de configuración centralizado usando **Spring Cloud Config**. Los demás microservicios se conectan a este servidor al iniciar para obtener su configuración específica según el perfil activo (dev, prod, etc.).