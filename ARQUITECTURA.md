# Arquitectura de Scan-Exporter Helm Chart

Este documento detalla la arquitectura limpia implementada en el chart de Scan-Exporter.

## Principios de Diseño

### Clean Architecture

La solución se estructura en capas independientes con responsabilidades claramente definidas:

```
┌─────────────────────────────────────┐
│   Capa de Observabilidad            │
│ (Pod Monitor, Prometheus Rules)     │
└─────────────────────────────────────┘
              ▲
              │
┌─────────────────────────────────────┐
│   Capa de Aplicación                │
│ (Deployment, Health Checks)         │
└─────────────────────────────────────┘
              ▲
              │
┌─────────────────────────────────────┐
│   Capa de Configuración             │
│ (ConfigMap, Valores Helm)           │
└─────────────────────────────────────┘
```

### Separación de Responsabilidades

**Capa de Configuración:**
- `values.yaml`: Parametrización de toda la infraestructura
- `config-map.yaml`: Definición de targets y políticas de escaneo
- Variables externalizadas para evitar acoplamiento

**Capa de Aplicación:**
- `deployment.yaml`: Orquestación del contenedor
- `_helpers.tpl`: Funciones reutilizables y DRY
- Gestión de recursos y probes de salud

**Capa de Observabilidad:**
- `pod-monitor.yaml`: Integración con Prometheus Operator
- `rules.yaml`: Alertas basadas en métricas
- Métricas expuestas en puerto 2112

## Componentes

### 1. ConfigMap (config-map.yaml)

```yaml
data:
  config.yaml: |
    timeout: 2           # Timeout global
    limit: 1024          # Límite de puertos
    targets:
      - name: "service"
        ip: "10.0.0.1"
        tcp:
          period: "10s"
          range: "reserved"
          expected: "443"
        icmp:
          period: "30s"
```

**Responsabilidades:**
- Define qué targets se monitorean
- Especifica políticas de escaneo por target
- Centraliza la lógica de negocio del monitoreo

### 2. Deployment (deployment.yaml)

```yaml
spec:
  containers:
  - name: scan-exporter
    image: devopsworks/scan-exporter:2.3.0
    args: ["-config", "/etc/scan-exporter/config.yaml"]
    volumeMounts:
    - name: config
      mountPath: "/etc/scan-exporter"
    livenessProbe:
      httpGet:
        path: /health
        port: 2112
```

**Responsabilidades:**
- Ejecuta la aplicación Scan-Exporter
- Inyecta configuración desde ConfigMap
- Valida salud continua mediante liveness probe
- Expone métricas en puerto 2112

### 3. PodMonitor (pod-monitor.yaml)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: scan-exporter
spec:
  podMetricsEndpoints:
  - interval: 10s
    port: metrics
    path: /metrics
```

**Responsabilidades:**
- Integración automática con Prometheus Operator
- Define scrape interval y endpoint
- Permite alertas automáticas en Prometheus

### 4. PrometheusRules (rules.yaml)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: scan-exporter
spec:
  groups:
  - name: scanexporter.rules
    rules:
    - alert: ICMPNotResponding
      expr: scanexporter_rtt_total == 0
      labels:
        severity: high
```

**Responsabilidades:**
- Define alertas basadas en métricas
- Evalúa expresiones PromQL
- Configura severidades y anotaciones

## Flujo de Datos

```
1. CONFIGURACIÓN
   values.yaml → ConfigMap (targets, políticas)

2. APLICACIÓN
   ConfigMap → Deployment (mount /etc/scan-exporter)
   Deployment → Contenedor (ejecuta scan-exporter -config)

3. ESCANEO
   Contenedor ejecuta:
   - ICMP ping a cada target
   - TCP port scan según configuración
   - Calcula RTT y validaciones

4. MÉTRICAS
   Contenedor expone en /metrics:
   - scanexporter_rtt_total
   - scanexporter_unexpected_open_ports_total
   - scanexporter_unexpected_closed_ports_total

5. OBSERVABILIDAD
   PodMonitor scrape /metrics cada 10s
   PrometheusRules evalúa alertas
   Prometheus dispara notificaciones
```

## Patrones Implementados

### Inyección de Dependencias (ConfigMap)

El ConfigMap actúa como inyector de configuración:

```yaml
# values.yaml
targets: |-
  timeout: 2
  targets:
    - name: "prod-db"
      ip: "10.0.1.10"

# templates/config-map.yaml
data:
  config.yaml: {{ .Values.targets | nindent 4 }}

# templates/deployment.yaml
args: ["-config", "/etc/scan-exporter/config.yaml"]
volumeMounts:
- name: config
  mountPath: "/etc/scan-exporter"
```

**Beneficios:**
- Configuración desacoplada de la aplicación
- Cambios sin redeploy si usas ConfigMap reloader
- Versionado y auditoría de cambios

### Health Checks (Liveness Probe)

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 2112
  initialDelaySeconds: 20
  periodSeconds: 3
```

**Beneficios:**
- Kubernetes detecta pods no saludables
- Reinicio automático si falla
- Evita estados zombi

### Condicionalidad (Helm Conditionals)

```yaml
{{- if .Values.podMonitor.enabled -}}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
...
{{- end }}

{{- if .Values.alertRules.enabled -}}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
...
{{- end }}
```

**Beneficios:**
- PodMonitor y Rules son opcionales
- Evita errores si Prometheus Operator no existe
- Flexibilidad en diferentes entornos

## Extensibilidad

### Agregar Nuevos Targets

```bash
helm upgrade scan-exporter . \
  --set targets="$(cat - << 'EOF'
timeout: 2
targets:
  - name: "new-service"
    ip: "10.0.2.50"
    tcp:
      period: "10s"
      range: "reserved"
      expected: "5432"
    icmp:
      period: "30s"
EOF
)"
```

### Cambiar Imagen

```bash
helm upgrade scan-exporter . \
  --set scanexporter.container.image=devopsworks/scan-exporter:2.4.0
```

### Personalizar Alertas

```bash
helm install scan-exporter . \
  --set alertRules.enabled=true \
  --set alertRules.namespace=monitoring \
  --values custom-alerts.yaml
```

## Flujo de Deployment

### Instalación Inicial

```bash
1. helm install scan-exporter . -n monitoring
   ├── Create ConfigMap (targets)
   ├── Create Deployment (scan-exporter pod)
   ├── Create PodMonitor (if enabled)
   └── Create PrometheusRule (if enabled)

2. Kubernetes scheduler
   ├── Asigna nodo
   ├── Descarga imagen
   ├── Monta ConfigMap
   └── Inicia contenedor

3. Liveness Probe
   ├── Espera 20s (initialDelaySeconds)
   ├── GET /health cada 3s
   ├── Pod = Ready cuando 200 OK

4. Prometheus Scrape
   ├── PodMonitor descubre pod
   ├── GET /metrics cada 10s
   └── Almacena métricas
```

### Actualización de Configuración

```bash
helm upgrade scan-exporter . --values new-values.yaml

1. Patch ConfigMap
2. Pod detecta cambio (si auto-reload está habilitado)
3. Escanea nuevos targets
4. Métricas se actualizan automáticamente
```

## Consideraciones de Seguridad

### Pod Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
```

### Network Policies

El chart puede integrarse con NetworkPolicy:

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scan-exporter
spec:
  podSelector:
    matchLabels:
      app: scan-exporter
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: ICMP
```

### Resource Limits

```yaml
resources:
  requests:
    memory: "100Mi"
    cpu: "200m"
  limits:
    memory: "150Mi"
    cpu: "375m"
```

Evita DoS interno por consumo excesivo de recursos.

## Monitoreo del Monitoreo

El chart puede ser monitoreado a sí mismo:

```yaml
# En Prometheus
# Verificar que scan-exporter esté vivo
up{job="scan-exporter"}

# Verificar que recolecta métricas
rate(scanexporter_rtt_total[5m])

# Alertar si el propio pod falla
- alert: ScanExporterDown
  expr: up{job="scan-exporter"} == 0
  for: 5m
```

## Validación y Testing

### Validar Syntaxis

```bash
helm lint ./scan-exporter
```

### Template Validation

```bash
helm template ./scan-exporter
```

### Dry Run

```bash
helm install --dry-run --debug scan-exporter .
```

### Testing en Staging

```bash
helm install test-scan-exporter . -n test
kubectl get all -n test
kubectl logs -n test -l app=scan-exporter
```

## Conclusión

La arquitectura de Scan-Exporter Helm Chart sigue Clean Architecture mediante:

1. **Separación en capas**: Configuración, Aplicación, Observabilidad
2. **Inyección de dependencias**: ConfigMap como proveedor de configuración
3. **Condicionalidad**: Componentes opcionales basados en valores
4. **Responsabilidad única**: Cada template tiene un propósito claro
5. **Reutilización**: _helpers.tpl evita duplicación
6. **Extensibilidad**: Fácil de personalizar y escalar

Este diseño garantiza mantenibilidad, testabilidad y escalabilidad en entornos Kubernetes.
