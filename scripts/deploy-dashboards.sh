#!/bin/bash

# Script de Deployment y Monitoreo para Dashboards

set -e

NAMESPACE="icesi-dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_kubernetes() {
    print_header "Verificando conexión a Kubernetes"
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "No se pudo conectar al cluster de Kubernetes"
        exit 1
    fi
    
    print_success "Kubernetes disponible"
}

check_namespace() {
    print_header "Verificando namespace: $NAMESPACE"
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE no existe, creando..."
        kubectl create namespace $NAMESPACE
        print_success "Namespace creado"
    else
        print_success "Namespace existe"
    fi
}

deploy_monitoring() {
    print_header "Deployando stack de monitoreo"
    
    # Deploy Prometheus
    print_warning "Deployando Prometheus..."
    kubectl apply -f "$SCRIPT_DIR/k8s/prometheus.yaml"
    print_success "Prometheus deployed"
    
    # Deploy Grafana
    print_warning "Deployando Grafana..."
    kubectl apply -f "$SCRIPT_DIR/k8s/grafana.yaml"
    print_success "Grafana deployed"
    
    # Esperar a que estén listos
    print_warning "Esperando a que los pods estén listos..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n $NAMESPACE --timeout=300s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=300s 2>/dev/null || true
    
    print_success "Stack de monitoreo deployado"
}

check_status() {
    print_header "Estado de los componentes"
    
    echo -e "\n${BLUE}Prometheus:${NC}"
    kubectl get pods -n $NAMESPACE -l app=prometheus
    
    echo -e "\n${BLUE}Grafana:${NC}"
    kubectl get pods -n $NAMESPACE -l app=grafana
    
    echo -e "\n${BLUE}Zipkin:${NC}"
    kubectl get pods -n $NAMESPACE -l app=zipkin 2>/dev/null || echo "Zipkin no encontrado"
}

port_forward_grafana() {
    print_header "Configurando acceso a Grafana"
    
    echo -e "${YELLOW}Iniciando port-forward para Grafana...${NC}"
    echo -e "${GREEN}Acceso: http://localhost:3000${NC}"
    echo -e "${GREEN}Usuario: admin${NC}"
    echo -e "${GREEN}Contraseña: admin${NC}"
    echo ""
    echo -e "${YELLOW}Presione Ctrl+C para detener${NC}"
    
    kubectl port-forward -n $NAMESPACE svc/grafana 3000:3000
}

port_forward_prometheus() {
    print_header "Configurando acceso a Prometheus"
    
    echo -e "${YELLOW}Iniciando port-forward para Prometheus...${NC}"
    echo -e "${GREEN}Acceso: http://localhost:9090${NC}"
    echo ""
    echo -e "${YELLOW}Presione Ctrl+C para detener${NC}"
    
    kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090
}

get_prometheus_targets() {
    print_header "Targets de Prometheus"
    
    # Obtener IP del pod de Prometheus
    PROM_POD=$(kubectl get pods -n $NAMESPACE -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$PROM_POD" ]; then
        print_error "No se encontró pod de Prometheus"
        return 1
    fi
    
    echo -e "${BLUE}Port-forward a Prometheus (en background)...${NC}"
    kubectl port-forward -n $NAMESPACE svc/prometheus 9091:9090 > /dev/null 2>&1 &
    PROM_PID=$!
    
    sleep 2
    
    curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, endpoint: .discoveredLabels.endpoint, state: .health}' || print_error "Error consultando Prometheus"
    
    kill $PROM_PID 2>/dev/null || true
}

delete_monitoring() {
    print_header "Eliminando stack de monitoreo"
    
    echo -e "${YELLOW}¿Está seguro? (s/n)${NC}"
    read -r confirmation
    
    if [ "$confirmation" = "s" ] || [ "$confirmation" = "S" ]; then
        kubectl delete -f "$SCRIPT_DIR/k8s/prometheus.yaml" --ignore-not-found
        kubectl delete -f "$SCRIPT_DIR/k8s/grafana.yaml" --ignore-not-found
        print_success "Stack de monitoreo eliminado"
    else
        print_warning "Operación cancelada"
    fi
}

local_docker_compose() {
    print_header "Iniciando stack de monitoreo con Docker Compose"
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose no está instalado"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    docker-compose -f docker-compose.monitoring.yml up -d
    
    print_success "Stack iniciado"
    echo -e "\n${GREEN}Grafana: http://localhost:3000${NC}"
    echo -e "${GREEN}Prometheus: http://localhost:9090${NC}"
    echo -e "${GREEN}Zipkin: http://localhost:9411${NC}"
}

stop_docker_compose() {
    print_header "Deteniendo stack de Docker Compose"
    
    cd "$SCRIPT_DIR"
    docker-compose -f docker-compose.monitoring.yml down
    
    print_success "Stack detenido"
}

# Menu principal
show_menu() {
    echo ""
    echo -e "${BLUE}=== Gestor de Dashboards ===${NC}"
    echo "1. Deploy en Kubernetes"
    echo "2. Verificar estado"
    echo "3. Port-forward Grafana"
    echo "4. Port-forward Prometheus"
    echo "5. Ver targets de Prometheus"
    echo "6. Eliminar stack en Kubernetes"
    echo "7. Iniciar con Docker Compose (local)"
    echo "8. Detener Docker Compose"
    echo "9. Salir"
    echo ""
    read -p "Seleccione opción (1-9): " choice
}

# Main
main() {
    while true; do
        show_menu
        
        case $choice in
            1)
                check_kubernetes
                check_namespace
                deploy_monitoring
                ;;
            2)
                check_kubernetes
                check_status
                ;;
            3)
                check_kubernetes
                port_forward_grafana
                ;;
            4)
                check_kubernetes
                port_forward_prometheus
                ;;
            5)
                check_kubernetes
                get_prometheus_targets
                ;;
            6)
                check_kubernetes
                delete_monitoring
                ;;
            7)
                local_docker_compose
                ;;
            8)
                stop_docker_compose
                ;;
            9)
                print_success "¡Hasta pronto!"
                exit 0
                ;;
            *)
                print_error "Opción inválida"
                ;;
        esac
    done
}

main
