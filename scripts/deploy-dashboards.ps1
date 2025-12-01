# Script de Deployment y Monitoreo para Dashboards (Windows PowerShell)

param(
    [string]$Action = "menu"
)

$NAMESPACE = "icesi-dev"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Funciones de output
function Print-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Check-Kubernetes {
    Print-Header "Verificando conexión a Kubernetes"
    
    try {
        $null = kubectl cluster-info 2>$null
        Print-Success "Kubernetes disponible"
        return $true
    } catch {
        Print-Error "No se pudo conectar al cluster de Kubernetes"
        return $false
    }
}

function Check-Namespace {
    Print-Header "Verificando namespace: $NAMESPACE"
    
    $nsExists = kubectl get namespace $NAMESPACE 2>$null
    if ($nsExists) {
        Print-Success "Namespace existe"
    } else {
        Print-Warning "Namespace $NAMESPACE no existe, creando..."
        kubectl create namespace $NAMESPACE
        Print-Success "Namespace creado"
    }
}

function Deploy-Monitoring {
    Print-Header "Deployando stack de monitoreo"
    
    # Deploy Prometheus
    Print-Warning "Deployando Prometheus..."
    kubectl apply -f "$SCRIPT_DIR\..\k8s\prometheus.yaml"
    Print-Success "Prometheus deployed"
    
    # Deploy Grafana
    Print-Warning "Deployando Grafana..."
    kubectl apply -f "$SCRIPT_DIR\..\k8s\grafana.yaml"
    Print-Success "Grafana deployed"
    
    # Esperar a que estén listos
    Print-Warning "Esperando a que los pods estén listos (esto puede tomar un par de minutos)..."
    Start-Sleep -Seconds 5
    
    Print-Success "Stack de monitoreo deployado"
}

function Check-Status {
    Print-Header "Estado de los componentes"
    
    Write-Host "`nPrometheus:" -ForegroundColor Blue
    kubectl get pods -n $NAMESPACE -l app=prometheus
    
    Write-Host "`nGrafana:" -ForegroundColor Blue
    kubectl get pods -n $NAMESPACE -l app=grafana
    
    Write-Host "`nZipkin:" -ForegroundColor Blue
    kubectl get pods -n $NAMESPACE -l app=zipkin 2>$null
}

function Port-Forward-Grafana {
    Print-Header "Configurando acceso a Grafana"
    
    Write-Host "Iniciando port-forward para Grafana..." -ForegroundColor Yellow
    Write-Host "Acceso: http://localhost:3000" -ForegroundColor Green
    Write-Host "Usuario: admin" -ForegroundColor Green
    Write-Host "Contraseña: admin" -ForegroundColor Green
    Write-Host "`nPresione Ctrl+C para detener`n" -ForegroundColor Yellow
    
    kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000
}

function Port-Forward-Prometheus {
    Print-Header "Configurando acceso a Prometheus"
    
    Write-Host "Iniciando port-forward para Prometheus..." -ForegroundColor Yellow
    Write-Host "Acceso: http://localhost:9090" -ForegroundColor Green
    Write-Host "`nPresione Ctrl+C para detener`n" -ForegroundColor Yellow
    
    kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090
}

function Get-PrometheusTargets {
    Print-Header "Targets de Prometheus"
    
    try {
        # Crear background port-forward
        Write-Host "Port-forward a Prometheus (en background)..." -ForegroundColor Blue
        $portForwardJob = Start-Job -ScriptBlock { kubectl port-forward -n icesi-dev svc/prometheus 9091:9090 }
        
        Start-Sleep -Seconds 2
        
        $targets = curl.exe -s "http://localhost:9091/api/v1/targets" | ConvertFrom-Json
        
        if ($targets.data.activeTargets) {
            $targets.data.activeTargets | ForEach-Object {
                Write-Host "Job: $($_.labels.job) | Endpoint: $($_.discoveredLabels.endpoint) | State: $($_.health)"
            }
        } else {
            Print-Error "No hay targets activos"
        }
        
        Stop-Job -Job $portForwardJob -ErrorAction SilentlyContinue
        Remove-Job -Job $portForwardJob -ErrorAction SilentlyContinue
    } catch {
        Print-Error "Error consultando Prometheus"
    }
}

function Delete-Monitoring {
    Print-Header "Eliminando stack de monitoreo"
    
    $confirmation = Read-Host "¿Está seguro? (s/n)"
    
    if ($confirmation -eq "s" -or $confirmation -eq "S") {
        kubectl delete -f "$SCRIPT_DIR\..\k8s\prometheus.yaml" --ignore-not-found 2>$null
        kubectl delete -f "$SCRIPT_DIR\..\k8s\grafana.yaml" --ignore-not-found 2>$null
        Print-Success "Stack de monitoreo eliminado"
    } else {
        Print-Warning "Operación cancelada"
    }
}

function Local-DockerCompose {
    Print-Header "Iniciando stack de monitoreo con Docker Compose"
    
    Push-Location "$SCRIPT_DIR\.."
    docker-compose -f docker-compose.monitoring.yml up -d
    Pop-Location
    
    Print-Success "Stack iniciado"
    Write-Host "`nGrafana: http://localhost:3000" -ForegroundColor Green
    Write-Host "Prometheus: http://localhost:9090" -ForegroundColor Green
    Write-Host "Zipkin: http://localhost:9411" -ForegroundColor Green
}

function Stop-DockerCompose {
    Print-Header "Deteniendo stack de Docker Compose"
    
    Push-Location "$SCRIPT_DIR\.."
    docker-compose -f docker-compose.monitoring.yml down
    Pop-Location
    
    Print-Success "Stack detenido"
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== Gestor de Dashboards ===" -ForegroundColor Blue
    Write-Host "1. Deploy en Kubernetes"
    Write-Host "2. Verificar estado"
    Write-Host "3. Port-forward Grafana"
    Write-Host "4. Port-forward Prometheus"
    Write-Host "5. Ver targets de Prometheus"
    Write-Host "6. Eliminar stack en Kubernetes"
    Write-Host "7. Iniciar con Docker Compose (local)"
    Write-Host "8. Detener Docker Compose"
    Write-Host "9. Salir"
    Write-Host ""
}

function Main {
    while ($true) {
        Show-Menu
        $choice = Read-Host "Seleccione opción (1-9)"
        
        switch ($choice) {
            "1" {
                if (Check-Kubernetes) {
                    Check-Namespace
                    Deploy-Monitoring
                }
            }
            "2" {
                if (Check-Kubernetes) {
                    Check-Status
                }
            }
            "3" {
                if (Check-Kubernetes) {
                    Port-Forward-Grafana
                }
            }
            "4" {
                if (Check-Kubernetes) {
                    Port-Forward-Prometheus
                }
            }
            "5" {
                if (Check-Kubernetes) {
                    Get-PrometheusTargets
                }
            }
            "6" {
                if (Check-Kubernetes) {
                    Delete-Monitoring
                }
            }
            "7" {
                Local-DockerCompose
            }
            "8" {
                Stop-DockerCompose
            }
            "9" {
                Print-Success "¡Hasta pronto!"
                exit 0
            }
            default {
                Print-Error "Opción inválida"
            }
        }
        
        Write-Host ""
        pause
    }
}

# Ejecutar
if ($Action -eq "menu") {
    Main
} else {
    switch ($Action) {
        "deploy" { if (Check-Kubernetes) { Check-Namespace; Deploy-Monitoring } }
        "status" { if (Check-Kubernetes) { Check-Status } }
        "grafana" { if (Check-Kubernetes) { Port-Forward-Grafana } }
        "prometheus" { if (Check-Kubernetes) { Port-Forward-Prometheus } }
        "targets" { if (Check-Kubernetes) { Get-PrometheusTargets } }
        "delete" { if (Check-Kubernetes) { Delete-Monitoring } }
        "docker-up" { Local-DockerCompose }
        "docker-down" { Stop-DockerCompose }
        default { Write-Host "Acción no reconocida: $Action" -ForegroundColor Red }
    }
}
