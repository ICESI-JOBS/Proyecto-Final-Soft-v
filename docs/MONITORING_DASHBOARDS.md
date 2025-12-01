# Monitoring & Dashboards Implementation

## Overview

Se ha implementado una solución completa de monitoreo y dashboards para los microservicios utilizando **Prometheus** y **Grafana**. Esta solución permite visualizar en tiempo real el estado de salud, rendimiento y métricas de cada servicio.

## Componentes Instalados

### 1. **Prometheus**
- **Rol**: Servidor de almacenamiento de series temporales
- **Puerto**: 9090
- **Función**: Recolecta métricas de todos los microservicios cada 15 segundos
- **Retención**: 15 días
- **Ubicación K8s**: `k8s/prometheus.yaml`

### 2. **Grafana**
- **Rol**: Plataforma de visualización
- **Puerto**: 3000
- **Función**: Muestra dashboards interactivos y personalizables
- **Ubicación K8s**: `k8s/grafana.yaml`

### 3. **Dashboards Creados**

#### Sistema General
- **System Overview Dashboard**: Vista consolidada de todos los servicios
  - Servicios saludables vs no saludables
  - Tasa total de solicitudes
  - Comparación de tasas de error entre servicios

#### Por Servicio
1. **API Gateway Dashboard**
   - Tasa de solicitudes
   - Cantidad de errores
   - Latencia percentiles (p95, p99)

2. **User Service Dashboard**
   - Tasa de solicitudes
   - Distribución de estados HTTP
   - Latencia percentiles
   - Tasa de error

3. **Product Service Dashboard**
   - Tasa de solicitudes
   - Distribución de estados HTTP
   - Latencia percentiles
   - Throughput

4. **Order Service Dashboard**
   - Tasa de órdenes procesadas
   - Cantidad de errores
   - Latencia percentiles
   - Estados de órdenes

5. **Payment Service Dashboard**
   - Tasa de transacciones
   - Tasa de error
   - Latencia de transacciones
   - Distribución de estados HTTP

6. **Shipping Service Dashboard**
   - Tasa de envíos
   - Distribución de estados de envío
   - Latencia percentiles
   - Tasa de error

7. **Favourite Service Dashboard**
   - Tasa de solicitudes
   - Distribución de estados HTTP
   - Latencia percentiles

## Deployment

### Opción 1: Docker Compose (Desarrollo)

```bash
# En el directorio raíz del proyecto
docker-compose -f docker-compose.monitoring.yml up -d
```

Acceder a:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

### Opción 2: Kubernetes (Producción)

```bash
# Aplicar configuración de Prometheus
kubectl apply -f k8s/prometheus.yaml

# Aplicar configuración de Grafana
kubectl apply -f k8s/grafana.yaml

# Verificar deployment
kubectl get pods -n icesi-dev | grep -E "prometheus|grafana"
```

Acceder a Grafana:
```bash
kubectl port-forward -n icesi-dev svc/grafana 3000:3000
# Luego: http://localhost:3000
```

## Configuración de Servicios

### Requisitos en cada Microservicio

Asegúrese que cada servicio tenga las siguientes dependencias en el `pom.xml`:

```xml
<!-- Micrometer Prometheus Registry -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>

<!-- Spring Boot Actuator -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<!-- Spring Cloud Sleuth para trazas distribuidas -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>

<!-- Zipkin para trazas distribuidas -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

### Configuración en application.yml

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
  endpoint:
    health:
      show-details: always

# Configuración de Sleuth para trazas
spring:
  sleuth:
    sampler:
      probability: 1.0
  zipkin:
    base-url: http://zipkin:9411
```

## Métricas Monitoreadas

### Por cada servicio se capturan:

1. **Métricas HTTP**
   - `http_server_requests_seconds_count`: Total de solicitudes
   - `http_server_requests_seconds_sum`: Suma de latencias
   - `http_server_requests_seconds_max`: Latencia máxima
   - Desglosadas por: `method`, `status`, `uri`

2. **Métricas JVM**
   - Uso de memoria
   - Threads activos
   - Garbage collection

3. **Métricas de Negocio** (personalizables)
   - Órdenes procesadas
   - Transacciones completadas
   - Productos consultados

## Alertas Recomendadas

Para mejorar aún más el monitoreo, se pueden configurar alertas en Prometheus:

```yaml
groups:
  - name: ecommerce
    rules:
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "Alta tasa de errores en {{ $labels.job }}"

      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) > 1
        for: 5m
        annotations:
          summary: "Latencia alta en {{ $labels.job }}"

      - alert: ServiceDown
        expr: up{job=~".*-service|api-gateway"} == 0
        for: 1m
        annotations:
          summary: "{{ $labels.job }} está caído"
```

## Estructura de Archivos Creados

```
proyecto-final/
├── k8s/
│   ├── prometheus.yaml           # Deployment y ConfigMap de Prometheus
│   ├── grafana.yaml              # Deployment de Grafana
│   └── grafana-dashboards-configmap.yaml
├── dashboards/
│   ├── api-gateway-dashboard.json
│   ├── user-service-dashboard.json
│   ├── product-service-dashboard.json
│   ├── order-service-dashboard.json
│   ├── payment-service-dashboard.json
│   ├── shipping-service-dashboard.json
│   ├── favourite-service-dashboard.json
│   └── system-overview-dashboard.json
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yaml
│       └── dashboards/
│           └── dashboards.yaml
├── prometheus.yml                # Configuración de Prometheus
└── docker-compose.monitoring.yml # Docker Compose para desarrollo
```

## Acceso a los Dashboards

### Credenciales por Defecto
- **Usuario**: admin
- **Contraseña**: admin

### URLs de los Dashboards
Una vez en Grafana, accesible en `/d/`:
- System Overview: `/d/system-overview-dashboard`
- API Gateway: `/d/api-gateway-dashboard`
- User Service: `/d/user-service-dashboard`
- Product Service: `/d/product-service-dashboard`
- Order Service: `/d/order-service-dashboard`
- Payment Service: `/d/payment-service-dashboard`
- Shipping Service: `/d/shipping-service-dashboard`
- Favourite Service: `/d/favourite-service-dashboard`

## Métricas Clave en los Dashboards

### Latencia
- **p50, p95, p99**: Percentiles de latencia en milisegundos
- Indican el rendimiento general del servicio

### Tasa de Error
- **5xx Errors**: Errores del servidor
- **4xx Errors**: Errores del cliente
- Expresados como porcentaje o conteo

### Throughput
- **Requests/sec**: Solicitudes procesadas por segundo
- Indicador de carga en el sistema

### Disponibilidad
- **Healthy Services**: Servicios respondiendo correctamente
- **Unhealthy Services**: Servicios con problemas

## Mantenimiento y Mejoras Futuras

1. **AlertManager**: Integrar para notificaciones vía Slack/Email
2. **Loki**: Agregar agregación de logs centralizada
3. **Custom Metrics**: Implementar métricas específicas del negocio
4. **Recording Rules**: Pre-computar queries costosas
5. **SLO/SLI**: Definir objetivos de nivel de servicio

## Comandos Útiles

```bash
# Ver métricas disponibles en Prometheus
curl http://localhost:9090/api/v1/targets

# Consultar métrica específica
curl 'http://localhost:9090/api/v1/query?query=up'

# Ver series temporales disponibles
curl http://localhost:9090/api/v1/series

# Acceder a Grafana
curl http://localhost:3000/api/datasources
```

## Troubleshooting

### Los dashboards no muestran datos
1. Verificar que Prometheus está recolectando métricas
2. Confirmar que los servicios están en `/actuator/prometheus`
3. Revisar logs de Prometheus: `kubectl logs -n icesi-dev -f prometheus-xxx`

### Servicios no aparecen en Prometheus
1. Verificar conectividad entre Prometheus y servicios
2. Revisar configuración de scrape_configs en prometheus.yaml
3. Confirmar que los servicios están exponiendo métricas

### Grafana no se conecta a Prometheus
1. Verificar que Prometheus está activo
2. Revisar URL del datasource en Grafana
3. Comprobar configuración de red entre contenedores/pods
