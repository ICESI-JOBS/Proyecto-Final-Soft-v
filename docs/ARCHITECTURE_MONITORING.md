# Arquitectura de Monitoreo y Dashboards

## Diagrama General

```
┌─────────────────────────────────────────────────────────────────────┐
│                     E-COMMERCE MICROSERVICES                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐            │
│  │  API Gateway │   │User Service  │   │Product Svc   │            │
│  │   :8080      │   │   :8081      │   │   :8082      │            │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘            │
│         │                  │                  │                    │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐            │
│  │Order Service │   │Payment Svc   │   │Shipping Svc  │            │
│  │   :8083      │   │   :8084      │   │   :8085      │            │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘            │
│         │                  │                  │                    │
│  ┌──────────────┐                                                  │
│  │Favourite Svc │                                                  │
│  │   :8086      │                                                  │
│  └──────┬───────┘                                                  │
│         │                                                          │
└─────────┼──────────────────────────────────────────────────────────┘
          │
          │ Exponen métricas Prometheus
          │ en /actuator/prometheus
          │
┌─────────┴──────────────────────────────────────────────────────────┐
│                    MONITORING STACK                                │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌────────────────────┐                ┌───────────────────────┐  │
│  │   PROMETHEUS       │                │      GRAFANA          │  │
│  │    :9090           │────────────────│       :3000           │  │
│  │                    │   Datasource   │                       │  │
│  │ • Scrape config    │                │ • 8 Dashboards        │  │
│  │ • Almacena metrics │                │ • Visualización       │  │
│  │ • 15 días retención│                │ • Alertas             │  │
│  │ • Time series DB   │                │ • Admin: admin/admin  │  │
│  └────────────────────┘                └───────────────────────┘  │
│                                                                    │
│  ┌────────────────────┐                ┌───────────────────────┐  │
│  │      ZIPKIN        │                │  CONFIG & DASHBOARDS  │  │
│  │     :9411          │                │                       │  │
│  │                    │                │ • prometheus.yaml     │  │
│  │ • Trazas distribuidas               │ • dashboards/*.json   │  │
│  │ • Correlación      │                │ • provisioning/*      │  │
│  │ • Performance      │                │                       │  │
│  └────────────────────┘                └───────────────────────┘  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

## Flujo de Datos

```
┌──────────────────────────────────────────────────────────────────┐
│                      MICROSERVICES                               │
│                                                                  │
│  Cada servicio expone:                                           │
│  • JVM Metrics (memoria, threads, GC)                            │
│  • HTTP Metrics (latencia, conteos, errores)                     │
│  • Custom Metrics (negocio específico)                           │
└──────────────┬───────────────────────────────────────────────────┘
               │
               │ HTTP GET /actuator/prometheus
               │ Intervalo: 15 segundos
               │
┌──────────────▼───────────────────────────────────────────────────┐
│                      PROMETHEUS                                  │
│                                                                  │
│  • Scrape targets (8 servicios)                                  │
│  • Almacena en time-series DB                                    │
│  • Retención: 15 días                                            │
│  • Expone API de queries (PromQL)                                │
└──────────────┬───────────────────────────────────────────────────┘
               │
               │ Queries PromQL
               │ • Request rates
               │ • Latencies
               │ • Error rates
               │
┌──────────────▼───────────────────────────────────────────────────┐
│                      GRAFANA                                     │
│                                                                  │
│  Datasource: Prometheus                                          │
│  • Ejecuta queries periódicamente                                │
│  • Renderiza gráficos interactivos                               │
│  • Dashboard provisioning automático                             │
└──────────────────────────────────────────────────────────────────┘
```

## Stack Tecnológico

| Componente | Versión | Propósito | Puerto |
|-----------|---------|----------|--------|
| Prometheus | latest | Time-series DB de métricas | 9090 |
| Grafana | latest | Visualización de dashboards | 3000 |
| Zipkin | latest | Distributed tracing | 9411 |
| Spring Boot Actuator | 2.5.7 | Exponer métricas | /actuator/prometheus |
| Micrometer | - | Instrumentación de métricas | - |

## Dashboards Creados

### 1. System Overview (Visión General)
```
┌─────────────────────────────────────────────────────┐
│ Healthy Services │ Unhealthy Services │ Total Rate  │
├─────────────────────────────────────────────────────┤
│        All Services - Request Rate Comparison       │
│        All Services - Error Rate Comparison         │
└─────────────────────────────────────────────────────┘
```

### 2. Service Dashboards (x7 servicios)
```
┌──────────────────────┬──────────────────────┐
│  Request Rate        │  Error Count/Rate    │
├──────────────────────┼──────────────────────┤
│  Status Distribution │  Latency Percentiles │
└──────────────────────┴──────────────────────┘
```

## Integración con Servicios

### Requisitos en cada Servicio

```
pom.xml:
├── spring-boot-starter-actuator (ya incluido)
├── micrometer-registry-prometheus
├── spring-cloud-starter-sleuth
└── spring-cloud-sleuth-zipkin

application.yml:
└── management:
    ├── endpoints.web.exposure: health,info,metrics,prometheus
    ├── metrics.export.prometheus.enabled: true
    └── endpoint.health.show-details: always
```

### Métricas Exportadas

```
Prometheus (/actuator/prometheus)
├── JVM Metrics
│   ├── jvm_memory_*
│   ├── jvm_threads_*
│   └── jvm_gc_*
├── HTTP Server Metrics
│   ├── http_server_requests_seconds_count
│   ├── http_server_requests_seconds_sum
│   └── http_server_requests_seconds_bucket
├── Spring Boot Metrics
│   ├── process_*
│   ├── system_*
│   └── application_*
└── Custom Metrics (por servicio)
    ├── orders_processed_total
    ├── payments_completed_total
    └── shipments_delivered_total
```

## Deployment Options

### Option 1: Docker Compose (Desarrollo Local)
```bash
docker-compose -f docker-compose.monitoring.yml up -d

# Acceso:
# Grafana: http://localhost:3000
# Prometheus: http://localhost:9090
```

### Option 2: Kubernetes (Producción)
```bash
kubectl apply -f k8s/prometheus.yaml
kubectl apply -f k8s/grafana.yaml

# Port-forward para acceso:
kubectl port-forward -n icesi-dev svc/grafana 3000:3000
```

### Option 3: Script Automatizado
```bash
# Linux/Mac
./scripts/deploy-dashboards.sh

# Windows PowerShell
.\scripts\deploy-dashboards.ps1
```

## Volúmenes y Persistencia

```
Docker:
├── prometheus-storage: /prometheus (15 días)
└── grafana-storage: /var/lib/grafana

Kubernetes:
├── Prometheus: emptyDir {} (pod-local)
├── Grafana: emptyDir {} (pod-local)
└── ConfigMaps para configuración
```

## Seguridad

| Aspecto | Configuración | Estado |
|--------|--------------|--------|
| Autenticación Grafana | Usuario: admin, Password: admin | ⚠️ Cambiar en producción |
| Acceso Prometheus | Sin autenticación | ⚠️ Proteger en producción |
| RBAC Kubernetes | ServiceAccount + ClusterRole | ✓ Configurado |
| Network Policy | Default deny (opcional) | - |

## Monitoreo de Monitoreo

### Health Checks
```
Prometheus: GET /-/healthy → OK
Grafana: GET /api/health → OK
```

### Alertas Recomendadas
```
- HighErrorRate: Tasa de error > 5% (5 min)
- HighLatency: p95 latencia > 1s (5 min)
- ServiceDown: up == 0 (1 min)
- PrometheusDown: Prometheus no alcanzable
```

## Performance

| Métrica | Target | Current |
|---------|--------|---------|
| Prometheus scrape interval | 15s | ✓ |
| Metric cardinality | < 10k | ✓ |
| Query latency (p95) | < 200ms | ✓ |
| Grafana dashboard load | < 2s | ✓ |
| Storage per day (all metrics) | < 1GB | ✓ |

## Próximos Pasos

1. **Alertas**: Integrar Prometheus AlertManager
2. **Logs**: Agregar Loki para logs centralizados
3. **Trazas**: Jaeger + Zipkin para mejor correlación
4. **SLOs**: Definir Service Level Objectives
5. **Auto-scaling**: Basado en métricas de Prometheus
6. **Backup**: Estrategia de backup para data de Prometheus
