# PromQL Queries - Guía de Referencia

## Acceso
Prometheus console disponible en: `http://localhost:9090/graph`

## Queries por Categoría

### 🔍 Salud General del Sistema

#### Servicios Saludables
```promql
count(up{job=~"api-gateway|user-service|product-service|order-service|payment-service|shipping-service|favourite-service"} == 1)
```
**Descripción**: Cuenta cuántos servicios están corriendo

#### Servicios Caídos
```promql
count(up{job=~"api-gateway|user-service|product-service|order-service|payment-service|shipping-service|favourite-service"} == 0)
```
**Descripción**: Cuenta servicios no disponibles

#### Estado de Cada Servicio
```promql
up{job=~"api-gateway|user-service|product-service|order-service|payment-service|shipping-service|favourite-service"}
```
**Descripción**: Muestra estado individual (1=UP, 0=DOWN)

---

### 📊 Tasa de Solicitudes

#### Total de Solicitudes por Segundo (últimos 5 min)
```promql
sum(rate(http_server_requests_seconds_count[5m]))
```
**Descripción**: Throughput total del sistema

#### Por Servicio Individual
```promql
sum(rate(http_server_requests_seconds_count[5m])) by (job)
```
**Descripción**: Tasa de solicitudes desglosada por servicio

#### Por Método HTTP
```promql
sum(rate(http_server_requests_seconds_count[5m])) by (method)
```
**Descripción**: GET vs POST vs PUT vs DELETE

#### Por Endpoint
```promql
sum(rate(http_server_requests_seconds_count[5m])) by (uri)
```
**Descripción**: Solicitudes por ruta específica

---

### ⏱️ Latencia y Rendimiento

#### Latencia p50 (mediana)
```promql
histogram_quantile(0.50, rate(http_server_requests_seconds_bucket[5m])) * 1000
```
**Descripción**: Latencia mediana en milisegundos

#### Latencia p95
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) * 1000
```
**Descripción**: 95% de solicitudes más rápidas que esto

#### Latencia p99
```promql
histogram_quantile(0.99, rate(http_server_requests_seconds_bucket[5m])) * 1000
```
**Descripción**: 99% de solicitudes más rápidas que esto

#### Por Servicio - p95
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job="user-service"}[5m])) * 1000
```
**Descripción**: Reemplazar `user-service` con cualquier otro

#### Latencia Máxima
```promql
rate(http_server_requests_seconds_max[5m]) * 1000
```
**Descripción**: Solicitud más lenta en los últimos 5 minutos

---

### ❌ Errores y Fallos

#### Total de Errores 5xx
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
```
**Descripción**: Errores del servidor (total)

#### Total de Errores 4xx
```promql
sum(rate(http_server_requests_seconds_count{status=~"4.."}[5m]))
```
**Descripción**: Errores del cliente (total)

#### Tasa de Error en Porcentaje
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m]))
```
**Descripción**: % de solicitudes que fallan

#### Error Rate por Servicio
```promql
(sum(rate(http_server_requests_seconds_count{status=~"5..",job="user-service"}[5m])) / sum(rate(http_server_requests_seconds_count{job="user-service"}[5m]))) * 100
```
**Descripción**: % de errores para un servicio específico

#### Conteo Total de Errores
```promql
http_server_requests_seconds_count{status=~"5.."}
```
**Descripción**: Total acumulado de errores 5xx

#### Errores por Endpoint
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (uri)
```
**Descripción**: Cuál endpoint genera más errores

---

### 🔄 Distribución de Status HTTP

#### Todas las Respuestas
```promql
sum(rate(http_server_requests_seconds_count[5m])) by (status)
```
**Descripción**: Desglose completo por status code

#### Solo Exitosas (2xx)
```promql
sum(rate(http_server_requests_seconds_count{status=~"2.."}[5m]))
```

#### Solo Redirects (3xx)
```promql
sum(rate(http_server_requests_seconds_count{status=~"3.."}[5m]))
```

#### Solo Client Errors (4xx)
```promql
sum(rate(http_server_requests_seconds_count{status=~"4.."}[5m]))
```

#### Solo Server Errors (5xx)
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m]))
```

---

### 💾 Métricas JVM

#### Memoria Heap Usada
```promql
jvm_memory_used_bytes{area="heap"}
```
**Descripción**: Memoria Java actualmente en uso

#### Memoria Heap Máxima
```promql
jvm_memory_max_bytes{area="heap"}
```
**Descripción**: Límite máximo de memoria heap

#### Porcentaje Memoria Usada
```promql
(jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) * 100
```
**Descripción**: % de memoria heap utilizada

#### Threads Activos
```promql
jvm_threads_live
```
**Descripción**: Número de threads corriendo

#### Threads de Daemon
```promql
jvm_threads_daemon
```
**Descripción**: Threads de tipo daemon

#### Colecciones de Garbage Collection
```promql
rate(jvm_gc_collection_seconds_count[5m])
```
**Descripción**: GC por segundo

---

### 📈 Tendencias y Cambios

#### Tasa de Solicitudes - Últimas 24h
```promql
rate(http_server_requests_seconds_count[1h])
```
**Descripción**: Promedio horario

#### Aumento de Errores
```promql
increase(http_server_requests_seconds_count{status=~"5.."}[1h])
```
**Descripción**: Cuántos errores nuevos en la última hora

#### Comparación con Ayer (misma hora)
```promql
rate(http_server_requests_seconds_count[5m]) / on (job) group_left rate(http_server_requests_seconds_count[5m] offset 24h)
```
**Descripción**: Ratio de tráfico hoy vs ayer

---

### 🎯 Queries Complejas

#### Servicios Lentosando
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) * 1000 > 500
```
**Descripción**: Servicios con p95 > 500ms

#### Servicios con Errores
```promql
(sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) by (job) / sum(rate(http_server_requests_seconds_count[5m])) by (job)) > 0.05
```
**Descripción**: Servicios con tasa error > 5%

#### Endpoints Críticos Lentos
```promql
histogram_quantile(0.99, rate(http_server_requests_seconds_bucket{uri=~"/api/orders|/api/payments"}[5m])) * 1000
```
**Descripción**: Latencia p99 de endpoints críticos

#### Patrón de Carga por Hora
```promql
sum(rate(http_server_requests_seconds_count[1h])) by (hour(timestamp))
```
**Descripción**: Distribución de carga por hora del día

---

### 🔔 Alertas (Expresiones)

#### Alta Tasa de Error
```promql
sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m])) > 0.05
```
**Alerta**: Si error rate > 5%

#### Latencia Crítica
```promql
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket[5m])) * 1000 > 1000
```
**Alerta**: Si p95 latency > 1 segundo

#### Servicios Caídos
```promql
up == 0
```
**Alerta**: Si algún servicio se cae

#### Memoria Crítica
```promql
(jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) > 0.85
```
**Alerta**: Si memoria > 85%

---

## Ejemplos por Servicio

### API Gateway
```promql
# Request rate
rate(http_server_requests_seconds_count{job="api-gateway"}[5m])

# Error rate
sum(rate(http_server_requests_seconds_count{job="api-gateway",status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count{job="api-gateway"}[5m]))

# Latency p95
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job="api-gateway"}[5m])) * 1000
```

### User Service
```promql
# Usuarios activos (requests)
rate(http_server_requests_seconds_count{job="user-service"}[5m])

# Tiempo promedio de respuesta
rate(http_server_requests_seconds_sum{job="user-service"}[5m]) / rate(http_server_requests_seconds_count{job="user-service"}[5m])

# Status distribution
sum(rate(http_server_requests_seconds_count{job="user-service"}[5m])) by (status)
```

### Order Service
```promql
# Órdenes procesadas
rate(http_server_requests_seconds_count{job="order-service"}[5m])

# Tasa de error en órdenes
sum(rate(http_server_requests_seconds_count{job="order-service",status=~"5.."}[5m]))

# Latencia de órdenes
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job="order-service"}[5m])) * 1000
```

### Payment Service
```promql
# Transacciones por segundo
rate(http_server_requests_seconds_count{job="payment-service"}[5m])

# Tasa de fallos en pagos
sum(rate(http_server_requests_seconds_count{job="payment-service",status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count{job="payment-service"}[5m]))

# Latencia crítica de pagos
histogram_quantile(0.99, rate(http_server_requests_seconds_bucket{job="payment-service"}[5m])) * 1000
```

---

## Consejos de Optimización

1. **Range Vector**: `[5m]` = últimos 5 minutos. Cambiar según necesidad
   - `[1m]`: Más granular pero ruidoso
   - `[1h]`: Más suave pero menos detalle

2. **Offset**: Ver datos históricos
   ```promql
   rate(http_server_requests_seconds_count[5m]) offset 1h  # Hace 1 hora
   ```

3. **Filters**: Filtrar resultados eficientemente
   ```promql
   http_server_requests_seconds_count{job="user-service",method="POST"}
   ```

4. **Recording Rules**: Para queries pesadas (futuro AlertManager)
   ```promql
   - record: service:http_request_rate:5m
     expr: rate(http_server_requests_seconds_count[5m])
   ```

---

## Dashboard Panels Templates

### Copiar estas queries a Grafana panels:

**Time Series Panel**:
- Title: "Request Rate"
- Metric: `rate(http_server_requests_seconds_count{job="$service"}[5m])`
- Legend: `{{job}}`

**Gauge Panel**:
- Title: "Error Rate"
- Metric: `sum(rate(http_server_requests_seconds_count{job="$service",status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count{job="$service"}[5m])) * 100`
- Thresholds: Green 0-5, Yellow 5-10, Red 10-100

**Bar Gauge**:
- Title: "Status Distribution"
- Metric: `sum(rate(http_server_requests_seconds_count{job="$service"}[5m])) by (status)`

---

## Recursos Adicionales

- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [MetricQL (VictoriaMetrics)](https://docs.victoriametrics.com/MetricQL.html)
- [Grafana PromQL Functions](https://grafana.com/docs/grafana/latest/dashboards/panels/query-options/)
