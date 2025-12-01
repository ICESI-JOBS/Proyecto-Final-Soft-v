# FinOps - Cost Optimization Analysis & Implementation Guide

## 1. Overview
Este documento detalla la implementación de FinOps (Financial Operations) para el proyecto ecommerce-app en Azure y Docker Compose, incluyendo monitoreo de costos, políticas de ahorro y optimización de recursos.

---

## 2. Costos Estimados Mensuales (Azure)

### 2.1 Escenario Actual (Sin Optimización)
| Recurso | SKU | Cantidad | Costo Mensual | Notas |
|---------|-----|----------|---------------|-------|
| AKS Cluster | Standard_D2s_v3 | 3 nodos | $600 | On-demand instances |
| App Service Plans | Premium P1V2 | 2 | $200 | Microservicios escalables |
| Azure SQL Database | Standard S1 | 1 | $30 | 20 DTUs |
| Storage Account | Standard LRS | 1 | $25 | Almacenamiento general |
| Log Analytics | Pay-as-you-go | 1 GB/día | $50 | Retención 90 días |
| Application Insights | Pay-as-you-go | 1 | $25 | Monitoreo |
| **Total Estimado** | | | **$930/mes** | |

### 2.2 Escenario Optimizado (Con FinOps)
| Recurso | SKU | Cantidad | Costo Mensual | Ahorro | Estrategia |
|---------|-----|----------|---------------|---------|-----------|
| AKS Cluster | Spot B2s | 2 base + 1 burst | $180 | 70% | Spot instances |
| AKS Addons | Reserved Instances | 1 año | $120 | 40% | 1-year commitment |
| App Service Plans | B1 (Shared) | 2 | $50 | 75% | Tier reduction + scaling |
| Azure SQL Database | Standard S0 | 1 | $15 | 50% | DTU reduction |
| Storage Account | Standard LRS | 1 | $20 | 20% | Lifecycle management |
| Log Analytics | - | 1 GB/día | $30 | 40% | Retention: 30 días |
| Application Insights | - | 1 | $15 | 40% | Sampling enabled |
| **Total Optimizado** | | | **$430/mes** | **54%** | |

### 2.3 Ahorros Potenciales
- **Reducción mensual**: $500 USD (~$6,000/año)
- **ROI**: Implementación amortizada en 1-2 meses
- **Métrica**: De $930 → $430/mes

---

## 3. Políticas de Ahorro Implementadas

### 3.1 Spot Instances
```hcl
# En cost-optimization.tf
priority        = "Spot"
eviction_policy = "Deallocate"
```
**Ventajas**:
- 70-90% descuento vs On-demand
- Ideal para cargas de trabajo tolerantes a interrupciones
- Implementado en worker nodes no críticos

**Configuración**:
```yaml
# kubernetes cluster configuration
nodePoolSpot:
  priority: "Spot"
  spotMaxPrice: "0.05"  # USD por hora
  maxCount: 5
  minCount: 1
```

### 3.2 Auto-Scaling Horizontal
```yaml
# Escalado basado en métricas
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Scale-to-Zero Configuration**:
- Pods escalables a 0 réplicas durante horas de bajo tráfico
- Compatible con Kubernetes KEDA (event-driven autoscaling)

### 3.3 Reserved Instances & Commitments
- **3-year reservation**: 72% descuento
- **1-year reservation**: 55% descuento
- **Aplicable a**: AKS base nodes, Storage, Database

### 3.4 Políticas de Storage
```yaml
# Lifecycle management
lifecyclePolicies:
  - name: archiveOldBlobs
    rules:
      - selector: "*.log"
        daysAfterCreation: 30
        action: archive
      - selector: "*"
        daysAfterCreation: 90
        action: delete
```

---

## 4. Dashboards de Costos & Utilización

### 4.1 Grafana Dashboard
Ubicación: `dashboards/finops-cost-monitoring.json`

**Paneles Incluidos**:
1. **CPU Utilization** - Gráfico temporal de uso de CPU
2. **Memory Utilization** - Consumo de memoria por servicio
3. **Memory Distribution** - Pie chart de consumo por servicio
4. **CPU Distribution** - Pie chart de CPU por servicio
5. **Average CPU Gauge** - Métrica agregada de CPU
6. **Average Memory Gauge** - Métrica agregada de memoria
7. **Total Containers** - Recuento de contenedores activos
8. **Active Services** - Recuento de servicios UP

**Métricas Monitoreadas**:
```promql
# CPU Usage
rate(container_cpu_usage_seconds_total[5m])

# Memory Usage
container_memory_usage_bytes / container_memory_max_bytes

# Network
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])

# Disk I/O
rate(container_fs_reads_total[5m])
rate(container_fs_writes_total[5m])
```

### 4.2 Azure Cost Management
Acceso mediante:
1. **Portal de Azure**: Cost Management + Billing
2. **Análisis por etiquetas** (tags):
   - `environment: dev|staging|prod`
   - `project: ecommerce-app`
   - `cost_type: spot|regular|reserved`

---

## 5. Configuración de Alertas de Costos

### 5.1 Budget Alerts (cost-management.bicep)
```bicep
resource "azurerm_resource_group_cost_management_export" "monthly_export" {
  name                    = "monthly-cost-export"
  resource_group_name     = azurerm_resource_group.rg.name
  
  export_data_options {
    type                  = "Usage"
    time_period {
      period_from = "2025-01-01"
      period_to   = "2025-12-31"
    }
  }
}
```

**Configuración de Alertas**:
- Alert @ 50% del presupuesto
- Alert @ 75% del presupuesto
- Alert @ 100% del presupuesto
- Notificación a equipo FinOps

### 5.2 Alertas en Prometheus
```yaml
# prometheus-rules.yml
groups:
  - name: cost_alerts
    rules:
      - alert: HighCPUUtilization
        expr: avg(rate(container_cpu_usage_seconds_total[5m])) > 0.8
        for: 5m
        annotations:
          summary: "High CPU usage detected"
          impact: "Potential cost increase"
      
      - alert: HighMemoryUtilization
        expr: avg(container_memory_usage_bytes / container_memory_max_bytes) > 0.85
        for: 5m
        annotations:
          summary: "High memory usage detected"
          action: "Consider scaling or optimization"
```

---

## 6. Análisis de Optimización de Costos

### 6.1 Right-Sizing Analysis
```bash
# Script para analizar tamaño de recursos (PowerShell)
# Ubicación: finops/right-sizing-analysis.ps1

az container list --output json | \
  ConvertFrom-Json | \
  Select-Object -Property name, @{
    Name="CPU_Requested"; 
    Expression={$_.containers[0].resources.requests.cpu}
  }, @{
    Name="Memory_Requested_MB";
    Expression={[int]($_.containers[0].resources.requests.memory -replace 'Mi')}
  }, @{
    Name="Efficiency_Score";
    Expression={"Low"}  # Puede calcularse con datos reales
  }
```

### 6.2 Matriz de Decisión de Optimización
| Métrica | Actual | Objetivo | Acción |
|---------|--------|----------|--------|
| CPU Utilization Promedio | 45% | > 60% | Reducir request, usar Spot |
| Memory Utilization Promedio | 50% | > 70% | Aumentar densidad, reducir overhead |
| Costo por Contenedor/mes | $78 | < $40 | Consolidar, usar shared resources |
| Número de Nodos | 3 | 2-3 | Usar Spot burst nodes |
| Data Retention (Logs) | 90 días | 30 días | Reducir costo de storage |

### 6.3 Recomendaciones Específicas

#### A. Para AKS
1. **Implementar Spot Instances** para worker nodes no críticos
   ```bash
   # Crear node pool con Spot
   az aks nodepool add \
     --resource-group myResourceGroup \
     --cluster-name myAKSCluster \
     --name spotpool \
     --priority Spot \
     --spot-max-price 0.05
   ```

2. **Usar Reserved Instances** para base nodes (1-3 nodos base)

3. **Habilitar Cluster Autoscaler**
   ```bash
   az aks update \
     --resource-group myResourceGroup \
     --name myAKSCluster \
     --enable-cluster-autoscaling \
     --min-count 2 \
     --max-count 5
   ```

#### B. Para Storage
1. **Configurar Lifecycle Policies**
   - Archivos > 30 días → Cool storage
   - Archivos > 90 días → Archive storage
   - Archivos > 180 días → Delete
   - **Ahorro**: ~60% en storage costs

2. **Habilitar Deduplication** en SMB shares
   - **Ahorro**: 20-50% dependiendo del tipo de datos

#### C. Para Base de Datos
1. **Usar DTU Autoscaling** en SQL Database
   - Cambiar de S1 (20 DTU) a S0 (10 DTU) + elasticidad
   - **Ahorro**: ~50%

2. **Implementar Query Performance Insights**
   - Optimizar queries lentas
   - **Ahorro**: 15-20% en compute

#### D. Para Monitoring
1. **Reducir data retention**
   - Log Analytics: 90 días → 30 días = 60% menos costo
   - Application Insights: Habilitar sampling (10%)

2. **Usar Metrics vs Logs**
   - Algunos datos pueden ser métricas en lugar de logs
   - **Ahorro**: 80% menos datos almacenados

---

## 7. Implementation Roadmap

### Phase 1: Immediate (Week 1-2)
- [ ] Aplicar etiquetas (tags) a todos los recursos
- [ ] Configurar Cost Management + Budget Alerts
- [ ] Crear dashboard de Grafana
- [ ] Revisar actual utilization

**Ahorro esperado**: $100-150/mes

### Phase 2: Short-term (Week 3-4)
- [ ] Habilitar Spot Instances en AKS
- [ ] Configurar Auto-scaling
- [ ] Reducir data retention (90→30 días)
- [ ] Optimizar requests/limits de pods

**Ahorro esperado**: $250-300/mes acumulativo

### Phase 3: Medium-term (Month 2-3)
- [ ] Comprar Reserved Instances (1-year)
- [ ] Implementar Policy Enforcement (Policies)
- [ ] Right-size database
- [ ] Consolidar microservicios si es aplicable

**Ahorro esperado**: $400-450/mes acumulativo

### Phase 4: Long-term (Month 4+)
- [ ] Evaluar 3-year Reserved Instances
- [ ] Implementar FinOps governance
- [ ] Cost allocation por equipo/proyecto
- [ ] Continuous optimization

---

## 8. Herramientas Recomendadas

### Monitoreo
- ✅ **Azure Cost Management** - Nativo de Azure
- ✅ **Grafana** - Ya deployado
- ✅ **Prometheus** - Ya deployado
- 📦 **CloudHealth by VMware** - Tercero (opcional)
- 📦 **Cloudability** - Tercero (opcional)

### Automatización
- ✅ **Terraform** - Infrastructure as Code
- ✅ **Bicep** - Azure IaC
- 📦 **Policies** - Azure Policy para governance

### Reporting
- ✅ **Azure Advisor** - Recomendaciones automáticas
- ✅ **Cost Management Exports** - CSV/Blob Storage
- 📦 **Power BI** - Visualización avanzada (opcional)

---

## 9. KPIs y Métricas de Éxito

### Métricas Financieras
1. **Monthly Recurring Cost (MRC)**: $930 → $430 (-54%)
2. **Cost per Request**: Reducir 40%
3. **Cost per GB almacenado**: Reducir 60%
4. **Budget Variance**: < 5% vs presupuesto

### Métricas Operacionales
1. **Resource Utilization**: CPU >60%, Memory >70%
2. **Spot Instance Success Rate**: >95%
3. **Auto-scaling Response Time**: <2 minutos
4. **Service Availability**: 99.9%

### Métricas de FinOps
1. **Cloud Cost Awareness**: % de equipos conscientes de costos (Meta: 100%)
2. **Policy Compliance**: % de recursos que cumplen políticas (Meta: >95%)
3. **Optimization Rate**: Cambios implementados mensualmente (Meta: >2)
4. **Cost Reduction Achieved**: $ ahorrados vs baseline (Meta: >$6k/año)

---

## 10. Próximos Pasos

1. **Hoy**: Revisar este documento y confirmar presupuesto anual
2. **Mañana**: 
   - Ejecutar `cost-management.bicep` en Azure
   - Implementar `cost-optimization.tf`
   - Subir dashboard a Grafana
3. **Esta semana**:
   - Realizar análisis de right-sizing
   - Implementar Spot Instances en AKS
   - Configurar alertas de presupuesto
4. **Este mes**:
   - Completar Phase 1 & 2 del roadmap
   - Alcanzar $250-300/mes de ahorro
   - Revisar efectividad y ajustar

---

## Anexos

### A. URLs Útiles
- Azure Cost Management: https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu
- Grafana (Local): http://localhost:3000
- Prometheus (Local): http://localhost:9090
- Azure Advisor: https://portal.azure.com/#view/Microsoft_Azure_Expert/AdvisorMenuBlade

### B. Contactos
- **FinOps Lead**: finops@icesi.edu.co
- **Cloud Architect**: cloud-team@icesi.edu.co
- **DevOps Team**: devops@icesi.edu.co

### C. Referencias
- [Azure FinOps Documentation](https://learn.microsoft.com/en-us/azure/cost-management-billing/)
- [Kubernetes Cost Optimization](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/)
- [FinOps Foundation Best Practices](https://www.finops.org/)
