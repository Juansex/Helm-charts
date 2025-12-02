# Scan-Exporter Helm Chart

Un Helm chart profesional para desplegar **Scan-Exporter** en Kubernetes. Este proyecto implementa una arquitectura limpia enfocada en monitoreo proactivo de infraestructura mediante sondeos de disponibilidad y escaneo de puertos.

## Descripción General

Scan-Exporter es una herramienta de monitoreo que valida la disponibilidad y accesibilidad de servicios a través de:

- Pruebas ICMP (ping) para verificar reachability
- Escaneo de puertos TCP para validar servicios específicos
- Exportación de métricas en formato Prometheus
- Alertas automáticas basadas en reglas Prometheus

## Requisitos Previos

Antes de desplegar, verifica que tienes:

```bash
# Helm 3.x
helm version

# Acceso a cluster Kubernetes
kubectl cluster-info

# Acceso para crear deployments
kubectl auth can-i create deployments --namespace default

# (Opcional) Prometheus Operator para alertas automáticas
kubectl get crd prometheusrules.monitoring.coreos.com
```

## Arquitectura

El diseño sigue principios de Clean Architecture en 3 capas:

```
Capa de Configuración
├── values.yaml (Parámetros externalizados)
└── config-map.yaml (Targets y políticas de escaneo)

Capa de Aplicación
├── deployment.yaml (Orquestación del contenedor)
├── livenessProbe (Validación de salud continua)
└── volumeMounts (Inyección de configuración)

Capa de Observabilidad
├── pod-monitor.yaml (Integración Prometheus)
├── rules.yaml (Alertas automáticas)
└── Métricas expuestas en puerto 2112
```

Para entender profundamente el diseño, consulta **ARQUITECTURA.md**.

## Guía de Despliegue - Paso a Paso

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/Juansex/Helm-charts.git
cd Helm-charts/scan-exporter
```

### Paso 2: Crear Namespace

```bash
kubectl create namespace monitoring
```

### Paso 3: Configurar Targets

Editar `values.yaml` e indicar los targets a monitorear:

```yaml
targets: |-
  timeout: 2
  limit: 1024
  targets:
    - name: "servicios-criticos"
      ip: "192.168.1.100"
      tcp:
        period: "10s"
        range: "reserved"          # puertos 0-1023
        expected: "22,80,443"      # puertos esperados
      icmp:
        period: "30s"
```

**Opciones de rango TCP:**
- `reserved`: Puertos 0-1023 (servicios estándar)
- `registered`: Puertos 1024-49151
- `all`: Todos los puertos 0-65535

### Paso 4: Desplegar el Chart

```bash
# Instalación básica
helm install scan-exporter . -n monitoring

# Con valores personalizados
helm install scan-exporter . \
  -n monitoring \
  -f custom-values.yaml

# Con Prometheus Operator habilitado
helm install scan-exporter . \
  -n monitoring \
  --set podMonitor.enabled=true \
  --set alertRules.enabled=true \
  --set alertRules.namespace=monitoring
```

### Paso 5: Verificar Despliegue

```bash
# Estado del deployment
kubectl rollout status deployment/scan-exporter -n monitoring

# Verificar pod ejecutándose
kubectl get pods -n monitoring -l app=scan-exporter

# Ver logs
kubectl logs -f deployment/scan-exporter -n monitoring

# Probar health endpoint
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112
curl http://localhost:2112/health
```

### Paso 6: Acceder a Métricas

```bash
# Port-forward para Prometheus
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112

# Consultar métricas
curl http://localhost:2112/metrics
```

## Ejemplos de Uso

### Despliegue Básico Mínimo

```bash
# Crear namespace
kubectl create namespace monitoring

# Desplegar chart
helm install scan-exporter . -n monitoring

# Verificar
kubectl get pods -n monitoring
kubectl logs -n monitoring -l app=scan-exporter
```

### Monitoreo de Infraestructura Crítica

Validar servidores críticos (DB, Cache, API) con puertos esperados:

```yaml
targets: |-
  timeout: 2
  limit: 1024
  targets:
    # Base de datos PostgreSQL
    - name: "postgres-primary"
      ip: "10.0.1.10"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "5432"
      icmp:
        period: "20s"
    
    # Redis Cache
    - name: "redis-cluster"
      ip: "10.0.2.10"
      tcp:
        period: "10s"
        range: "registered"
        expected: "6379,6380,6381"
      icmp:
        period: "20s"
    
    # API Gateway
    - name: "api-gateway"
      ip: "10.0.3.10"
      tcp:
        period: "5s"
        range: "reserved"
        expected: "80,443"
      icmp:
        period: "10s"
```

### Monitoreo Multi-Tier

```yaml
targets: |-
  timeout: 2
  limit: 1024
  targets:
    # Servidores de base datos
    - name: "postgres-primary"
      ip: "10.0.1.10"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "5432"
      icmp:
        period: "30s"
    
    # Servicios web
    - name: "nginx-lb"
      ip: "10.0.2.10"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "80,443"
      icmp:
        period: "30s"
    
    # Infraestructura
    - name: "consul-server"
      ip: "10.0.3.10"
      tcp:
        period: "20s"
        range: "registered"
        expected: "8300,8301,8302,8500"
```

### Alta Disponibilidad

```bash
helm install scan-exporter . \
  -n monitoring \
  --set scanexporter.replicaCount=3 \
  --set podAntiAffinity=required \
  --set podMonitor.enabled=true \
  --set alertRules.enabled=true
```

## Configuración Avanzada

### Habilitar Prometheus Integration

Para integración automática con Prometheus Operator:

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set podMonitor.enabled=true \
  --set alertRules.enabled=true \
  --set alertRules.namespace=monitoring
```

Las alertas predefinidas son:

| Alerta | Severidad | Condición |
|--------|-----------|-----------|
| ICMPNotResponding | high | Target no responde ping |
| TooManyOpenPorts | high | Puertos abiertos inesperados |
| TooManyClosedPorts | critical | Puertos cerrados inesperados |

### Personalizar Recursos

```bash
helm install scan-exporter . \
  -n monitoring \
  --set scanexporter.resources.requests.memory=200Mi \
  --set scanexporter.resources.requests.cpu=300m \
  --set scanexporter.resources.limits.memory=300Mi \
  --set scanexporter.resources.limits.cpu=500m
```

### Actualizar Configuración

```bash
# Editar valores
helm upgrade scan-exporter . \
  -n monitoring \
  -f updated-values.yaml
```

### Cambiar Versión de Image

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set scanexporter.container.image=devopsworks/scan-exporter:2.4.0
```

## Métricas Exportadas

Scan-Exporter expone métricas Prometheus en formato estándar:

```
# HELP scanexporter_rtt_total Round Trip Time en ms
# TYPE scanexporter_rtt_total gauge
scanexporter_rtt_total{job="app1",name="app1",ip="198.51.100.1"} 15

# HELP scanexporter_unexpected_open_ports_total Puertos abiertos no esperados
# TYPE scanexporter_unexpected_open_ports_total gauge
scanexporter_unexpected_open_ports_total{job="app1",name="app1"} 0

# HELP scanexporter_unexpected_closed_ports_total Puertos cerrados no esperados
# TYPE scanexporter_unexpected_closed_ports_total gauge
scanexporter_unexpected_closed_ports_total{job="app1",name="app1"} 0
```

## Troubleshooting

### Pod no inicia

```bash
# Ver eventos del pod
kubectl describe pod -n monitoring -l app=scan-exporter

# Ver logs de error
kubectl logs -n monitoring -l app=scan-exporter --tail=50
```

### Métricas no se recopilan

```bash
# Verificar que PodMonitor esté creado
kubectl get podmonitor -n monitoring

# Verificar endpoint de métricas
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112
curl -s http://localhost:2112/metrics | head -20
```

### Alertas no disparan

```bash
# Verificar PrometheusRule
kubectl get prometheusrule -n monitoring

# Probar expresión PromQL en Prometheus
# En la UI de Prometheus: scanexporter_rtt_total == 0
```

## Desinstalar

```bash
helm uninstall scan-exporter -n monitoring
```

## Referencias

- [Repositorio Original](https://github.com/devops-works/scan-exporter)
- [Documentación Helm](https://helm.sh/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)

## Estructura del Proyecto

```
scan-exporter/
├── Chart.yaml                 # Metadatos del chart
├── values.yaml               # Valores por defecto
└── templates/
    ├── _helpers.tpl          # Funciones template reutilizables
    ├── deployment.yaml       # Orquestación de contenedor
    ├── config-map.yaml       # Configuración de targets
    ├── pod-monitor.yaml      # Integración Prometheus
    ├── rules.yaml            # Reglas de alertas
    └── NOTES.txt             # Instrucciones post-deploy
```

## Contribuciones

Este chart es un fork mantenido de [devops-works/helm-charts](https://github.com/devops-works/helm-charts).

## Licencia

Consultar archivo LICENSE en el repositorio raíz.
