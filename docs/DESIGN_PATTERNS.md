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

## Patrones de Resiliencia y Tolerancia a Fallos (Resilience Patterns)

Para asegurar que el sistema sea robusto y pueda manejar fallos en los servicios de los que depende, se utilizan patrones de resiliencia. Estos patrones ayudan a prevenir fallos en cascada y a mantener el sistema funcionando incluso cuando algunos de sus componentes fallan. En este proyecto, se utiliza la librería **Resilience4j** para implementar estos patrones.

### 1. Retry (Reintento)

- **Descripción**: Este patrón permite a una aplicación reintentar una operación que ha fallado un número predefinido de veces. Es útil para errores transitorios, como una falla momentánea de la red o un servicio temporalmente no disponible.
- **Implementación**: Se utiliza en servicios como `payment-service`. La configuración se define en el fichero `application.yml` de cada servicio, especificando el número máximo de reintentos (`max-attempts`) y el tiempo de espera entre ellos (`wait-duration`).
- **Ejemplo de Anotación**:
  ```java
  @Retry(name = "paymentFindAllRetry")
  ```
- **Ejemplo de Configuración** (`application.yml`):
  ```yaml
  resilience4j:
    retry:
      instances:
        paymentFindAllRetry:
          max-attempts: 3
          wait-duration: 500ms
  ```

### 2. Circuit Breaker (Cortocircuito)

- **Descripción**: El patrón Circuit Breaker previene que una aplicación intente ejecutar repetidamente una operación que es probable que falle. Después de un número configurable de fallos, el "circuito se abre" y las llamadas a la operación fallan inmediatamente sin intentar ejecutarla. Tras un período de espera, el circuito pasa a un estado de "medio abierto" para probar si el problema subyacente se ha resuelto.
- **Implementación**: Se utiliza en servicios como `order-service` y `payment-service` para proteger las llamadas a la base de datos y a otros servicios. Se define un método de `fallback` que se ejecuta cuando el circuito está abierto.
- **Ejemplo de Anotación**:
  ```java
  @CircuitBreaker(name = "orderDb", fallbackMethod = "fallbackFindAll")
  ```
- **Ejemplo de Configuración** (`application.yml`):
  ```yaml
  resilience4j:
    circuitbreaker:
      instances:
        orderDb:
          sliding-window-size: 10
          failure-rate-threshold: 50
          wait-duration-in-open-state: 5s
  ```

### 3. Bulkhead (Mamparo)

- **Descripción**: El patrón Bulkhead aísla los elementos de una aplicación en "pools" para que si uno falla, los demás puedan seguir funcionando. En el contexto de las llamadas a servicios, se limita el número de llamadas concurrentes a un componente específico. Esto evita que un servicio lento o que no responde acapare todos los recursos y cause un fallo en cascada en todo el sistema.
- **Implementación**: Se utiliza en `order-service` y `payment-service` para limitar las llamadas concurrentes. Se puede configurar para usar un `ThreadPool` para aislar las llamadas en hilos separados.
- **Ejemplo de Anotación**:
  ```java
  @Bulkhead(name = "orderDbBulkhead", type = Bulkhead.Type.THREADPOOL)
  ```
- **Ejemplo de Configuración** (`application.yml`):
  ```yaml
  resilience4j:
    bulkhead:
      instances:
        orderDbBulkhead:
          max-concurrent-calls: 10
  ```