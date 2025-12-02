# Scan-Exporter Helm Chart

Un Helm chart profesional para desplegar **Scan-Exporter** en Kubernetes. Este proyecto implementa una arquitectura limpia enfocada en monitoreo proactivo de infraestructura mediante sondeos de disponibilidad y escaneo de puertos.

## Visión General

Scan-Exporter es una herramienta de monitoreo que valida la disponibilidad y accesibilidad de servicios a través de:

- Pruebas ICMP (ping) para verificar reachability
- Escaneo de puertos TCP para validar servicios específicos
- Exportación de métricas en formato Prometheus
- Alertas automáticas basadas en reglas Prometheus

## Arquitectura

El diseño sigue principios de Clean Architecture:

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

### Componentes Principales

#### 1. **Deployment (deployment.yaml)**
- Ejecuta la imagen `devopsworks/scan-exporter:2.3.0`
- Monta configuración desde ConfigMap en `/etc/scan-exporter`
- Expone métricas en puerto 2112
- Liveness probe verifica `/health` cada 3 segundos

#### 2. **ConfigMap (config-map.yaml)**
- Define targets a escanear con políticas específicas
- Establece timeout y límites de puertos
- Configura intervalos y rangos de puertos por target

#### 3. **PodMonitor (pod-monitor.yaml)**
- Integración automática con Prometheus Operator
- Scrape interval: 10 segundos
- Endpoint: `/metrics`

#### 4. **PrometheusRules (rules.yaml)**
- Alertas sobre targets inaccesibles (ICMP)
- Advertencias sobre puertos inesperados
- Severidades configurables (high/critical)

## Guía de Despliegue

### Requisitos Previos

```bash
# Helm 3.x
helm version

# Acceso a cluster Kubernetes
kubectl cluster-info

# Prometheus Operator (opcional, recomendado)
kubectl get crd prometheusrules.monitoring.coreos.com
```

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/Juansex/Helm-charts.git
cd Helm-charts/scan-exporter
```

### Paso 2: Configurar Targets

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

### Paso 3: Desplegar el Chart

```bash
# Namespace específico
kubectl create namespace monitoring

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

### Paso 4: Verificar Despliegue

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

### Paso 5: Acceder a Métricas

```bash
# Port-forward para Prometheus
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112

# Consultar en navegador
curl http://localhost:2112/metrics
```

## Configuración Avanzada

### Habilitar PodMonitor

Para integración automática con Prometheus Operator:

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set podMonitor.enabled=true \
  --set podMonitor.path=/metrics
```

### Configurar Alertas

```bash
helm upgrade scan-exporter . \
  -n monitoring \
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

## Ejemplos de Configuración

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

### Configuración de Alta Disponibilidad

```bash
helm install scan-exporter . \
  -n monitoring \
  --set scanexporter.replicaCount=3 \
  --set podAntiAffinity=required \
  --set podMonitor.enabled=true \
  --set alertRules.enabled=true
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

## Gestión del Ciclo de Vida

### Actualizar Configuración

```bash
# Editar valores
helm upgrade scan-exporter . \
  -n monitoring \
  -f updated-values.yaml
```

### Cambiar Versión

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set scanexporter.container.image=devopsworks/scan-exporter:2.4.0
```

### Desinstalar

```bash
helm uninstall scan-exporter -n monitoring
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
