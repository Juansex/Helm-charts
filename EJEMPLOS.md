# Ejemplos Prácticos de Despliegue

Este documento proporciona ejemplos reales para diferentes escenarios de despliegue.

## 1. Despliegue Básico

### Instalación Mínima

```bash
# Crear namespace
kubectl create namespace monitoring

# Desplegar chart
helm install scan-exporter ./scan-exporter -n monitoring

# Verificar
kubectl get pods -n monitoring
kubectl logs -n monitoring -l app=scan-exporter
```

### Archivo: `basic-values.yaml`

```yaml
scanexporter:
  name: scan-exporter
  replicaCount: 1
  container:
    image: devopsworks/scan-exporter:2.3.0
    port: 2112
  resources:
    requests:
      memory: "100Mi"
      cpu: "200m"
    limits:
      memory: "150Mi"
      cpu: "375m"

targets: |-
  timeout: 2
  limit: 1024
  targets:
    - name: "google-dns"
      ip: "8.8.8.8"
      icmp:
        period: "30s"

podMonitor:
  enabled: false

alertRules:
  enabled: false
```

### Instalar

```bash
helm install scan-exporter ./scan-exporter \
  -n monitoring \
  -f basic-values.yaml
```

---

## 2. Monitoreo de Infraestructura Crítica

### Caso de Uso

Validar que servidores críticos (DB, Cache, API) estén disponibles y con puertos esperados abiertos.

### Archivo: `critical-infra-values.yaml`

```yaml
scanexporter:
  replicaCount: 2
  container:
    image: devopsworks/scan-exporter:2.3.0
    port: 2112
  resources:
    requests:
      memory: "200Mi"
      cpu: "300m"
    limits:
      memory: "300Mi"
      cpu: "500m"
  liveness:
    initialDelay: 30
    period: 5

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
    
    # Elasticsearch
    - name: "elasticsearch"
      ip: "10.0.4.10"
      tcp:
        period: "15s"
        range: "registered"
        expected: "9200,9300"
      icmp:
        period: "30s"

podMonitor:
  enabled: true
  path: /metrics

alertRules:
  enabled: true
  namespace: monitoring
  rules:
    - name: PostgreSQLDown
      expr: scanexporter_rtt_total{name="postgres-primary"} == 0
      severity: critical
      annotations:
        summary: "PostgreSQL primario no responde"
        description: "PostgreSQL en 10.0.1.10 está inaccesible"
    
    - name: RedisPortClosed
      expr: scanexporter_unexpected_closed_ports_total{name="redis-cluster"} > 0
      severity: high
      annotations:
        summary: "Redis tiene puertos cerrados inesperados"
        description: "Redis debería tener 6379,6380,6381 abiertos"
    
    - name: APIDown
      expr: scanexporter_rtt_total{name="api-gateway"} == 0
      severity: critical
      annotations:
        summary: "API Gateway no responde"
        description: "El API Gateway en 10.0.3.10 está inaccesible"
```

### Instalar

```bash
helm install scan-exporter-prod ./scan-exporter \
  -n monitoring \
  -f critical-infra-values.yaml
```

### Verificar Alertas

```bash
# Port-forward a Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Ir a http://localhost:9090
# Buscar: scanexporter_rtt_total
# Buscar: PrometheusRule

# Verificar alertas
kubectl get prometheusrule -n monitoring
kubectl get podmonitor -n monitoring
```

---

## 3. Monitoreo Multi-Región

### Caso de Uso

Validar disponibilidad de servicios en múltiples datacenters/regiones.

### Archivo: `multi-region-values.yaml`

```yaml
scanexporter:
  replicaCount: 3
  container:
    image: devopsworks/scan-exporter:2.3.0
    port: 2112
  resources:
    requests:
      memory: "256Mi"
      cpu: "500m"
    limits:
      memory: "512Mi"
      cpu: "1000m"

targets: |-
  timeout: 3
  limit: 2048
  targets:
    # Región US-EAST
    - name: "lb-us-east-1"
      ip: "52.10.1.1"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "80,443"
      icmp:
        period: "15s"
    
    - name: "db-us-east-1"
      ip: "10.100.1.10"
      tcp:
        period: "15s"
        range: "reserved"
        expected: "3306"
      icmp:
        period: "20s"
    
    # Región EU-WEST
    - name: "lb-eu-west-1"
      ip: "54.172.1.1"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "80,443"
      icmp:
        period: "15s"
    
    - name: "db-eu-west-1"
      ip: "10.200.1.10"
      tcp:
        period: "15s"
        range: "reserved"
        expected: "3306"
      icmp:
        period: "20s"
    
    # Región AP-SOUTHEAST
    - name: "lb-ap-southeast-1"
      ip: "13.251.1.1"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "80,443"
      icmp:
        period: "15s"
    
    - name: "db-ap-southeast-1"
      ip: "10.150.1.10"
      tcp:
        period: "15s"
        range: "reserved"
        expected: "3306"
      icmp:
        period: "20s"

podMonitor:
  enabled: true
  path: /metrics

alertRules:
  enabled: true
  namespace: monitoring
  rules:
    - name: RegionDown
      expr: count(scanexporter_rtt_total == 0) by (name) > 0
      severity: high
      annotations:
        summary: "Servicio no disponible en región {{ $labels.region }}"
        description: "{{ $labels.name }} no responde a ping"
```

### Instalar

```bash
helm install scan-exporter-multi-region ./scan-exporter \
  -n monitoring \
  -f multi-region-values.yaml
```

---

## 4. Despliegue con Seguridad Mejorada

### Caso de Uso

Desplegar en entorno con PodSecurityPolicy, RBAC y restricciones de red.

### Archivo: `secure-values.yaml`

```yaml
scanexporter:
  replicaCount: 2
  container:
    image: devopsworks/scan-exporter:2.3.0
    imagePullPolicy: IfNotPresent
    port: 2112
  resources:
    requests:
      memory: "150Mi"
      cpu: "250m"
    limits:
      memory: "200Mi"
      cpu: "400m"

targets: |-
  timeout: 2
  limit: 1024
  targets:
    - name: "internal-service"
      ip: "10.0.1.50"
      tcp:
        period: "20s"
        range: "reserved"
        expected: "443"
      icmp:
        period: "30s"

podMonitor:
  enabled: true
  path: /metrics

alertRules:
  enabled: true
  namespace: monitoring
```

### Template Adicional: `templates/podsecuritypolicy.yaml`

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: {{ include "scanexporter.fullname" . }}
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'downwardAPI'
    - 'emptyDir'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'MustRunAs'
    seLinuxOptions:
      level: "s0:c123,c456"
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1000
        max: 65535
  readOnlyRootFilesystem: false
```

### Template Adicional: `templates/networkpolicy.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "scanexporter.fullname" . }}
spec:
  podSelector:
    matchLabels:
      app: {{ include "scanexporter.fullname" . }}
  policyTypes:
    - Ingress
    - Egress
  
  # Permitir scrape desde Prometheus
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
      ports:
      - protocol: TCP
        port: 2112
  
  # Permitir salida para escaneo
  egress:
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: TCP
        port: 443
      - protocol: TCP
        port: 80
      - protocol: ICMP
    # Permitir DNS
    - to:
      - namespaceSelector: {}
      ports:
      - protocol: UDP
        port: 53
```

### Instalar

```bash
helm install scan-exporter-secure ./scan-exporter \
  -n monitoring \
  -f secure-values.yaml
```

---

## 5. Monitoreo Continuo con Replicaset

### Caso de Uso

Alta disponibilidad para monitoreo crítico en producción.

### Archivo: `ha-values.yaml`

```yaml
scanexporter:
  replicaCount: 3
  container:
    image: devopsworks/scan-exporter:2.3.0
    port: 2112
  resources:
    requests:
      memory: "256Mi"
      cpu: "500m"
    limits:
      memory: "384Mi"
      cpu: "750m"

targets: |-
  timeout: 2
  limit: 1024
  targets:
    - name: "critical-app"
      ip: "10.0.5.50"
      tcp:
        period: "5s"
        range: "reserved"
        expected: "443"
      icmp:
        period: "10s"

podMonitor:
  enabled: true
  path: /metrics

alertRules:
  enabled: true
  namespace: monitoring
  rules:
    - name: ServiceDown
      expr: scanexporter_rtt_total{name="critical-app"} == 0
      for: 2m
      severity: critical
      annotations:
        summary: "App crítica inaccesible por 2 minutos"
```

### Instalar con Anti-Affinity

```bash
helm install scan-exporter-ha ./scan-exporter \
  -n monitoring \
  -f ha-values.yaml \
  --set podAntiAffinity=required
```

### Template: Anti-Affinity en `templates/deployment.yaml`

```yaml
affinity:
  podAntiAffinity:
    {{- if eq .Values.podAntiAffinity "required" }}
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- else }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- end }}
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ include "scanexporter.fullname" . }}
      topologyKey: kubernetes.io/hostname
```

---

## 6. Despliegue con ConfigMap Auto-Reload

### Caso de Uso

Actualizar targets sin reiniciar pods.

### Template Adicional: `templates/configmap-reloader.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "scanexporter.fullname" . }}-reloader
  annotations:
    reloader.stakater.com/enabled: "true"
spec:
  config.yaml: |
    {{ .Values.targets | nindent 4 }}
```

### Actualizar Targets en Tiempo Real

```bash
# Editar targets
helm upgrade scan-exporter ./scan-exporter \
  -n monitoring \
  --set targets="$(cat new-targets.yaml)"

# ConfigMap Reloader detecta cambio
# Pods se recargan automáticamente
# Sin necesidad de rollout restart
```

---

## Comandos Útiles

### Despliegue

```bash
# Instalar
helm install scan-exporter ./scan-exporter -n monitoring

# Actualizar
helm upgrade scan-exporter ./scan-exporter -n monitoring

# Desinstalar
helm uninstall scan-exporter -n monitoring

# Ver historial
helm history scan-exporter -n monitoring

# Rollback
helm rollback scan-exporter 1 -n monitoring
```

### Debugging

```bash
# Ver valores aplicados
helm get values scan-exporter -n monitoring

# Ver manifiestos generados
helm get manifest scan-exporter -n monitoring

# Ver pod
kubectl get pod -n monitoring -l app=scan-exporter
kubectl describe pod -n monitoring -l app=scan-exporter
kubectl logs -n monitoring -l app=scan-exporter

# Ver métricas
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112
curl http://localhost:2112/metrics
```

### Monitoreo

```bash
# Ver PodMonitor
kubectl get podmonitor -n monitoring

# Ver PrometheusRule
kubectl get prometheusrule -n monitoring

# Ver alertas activas en Prometheus
# http://prometheus-ip:9090/alerts
```

---

## Conclusión

Estos ejemplos cubren:
- Despliegues básicos
- Infraestructura crítica
- Multi-región
- Seguridad
- Alta disponibilidad
- Auto-reload dinámico

Elige el que mejor se adapte a tu caso de uso.
