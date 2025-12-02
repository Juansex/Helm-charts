# Referencia Rápida

Resumen ejecutivo del proyecto Scan-Exporter Helm Chart.

## En 30 Segundos

**Qué es**: Helm chart profesional para desplegar Scan-Exporter en Kubernetes.

**Qué hace**: Monitorea disponibilidad de servidores mediante ICMP (ping) y TCP escaneo de puertos.

**Por qué**: Detección proactiva de problemas, integración Prometheus, alertas automáticas.

## En 3 Minutos

### Instalación

```bash
git clone https://github.com/Juansex/Helm-charts.git
cd Helm-charts/scan-exporter
helm install scan-exporter . -n monitoring
```

### Configuración

Editar `scan-exporter/values.yaml`:

```yaml
targets: |-
  timeout: 2
  targets:
    - name: "servidor"
      ip: "10.0.0.1"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "443"
      icmp:
        period: "30s"
```

### Verificación

```bash
kubectl logs -f deployment/scan-exporter -n monitoring
kubectl port-forward svc/scan-exporter 2112:2112 -n monitoring
curl http://localhost:2112/metrics
```

## Documentación

- **QUICKSTART.md** → Empezar aquí (5 min)
- **README.md** → Referencia completa (15 min)
- **ARQUITECTURA.md** → Diseño técnico (20 min)
- **EJEMPLOS.md** → Casos reales (casos específicos)
- **INDICE.md** → Guía de navegación

## Comandos Clave

```bash
# Instalar
helm install scan-exporter ./scan-exporter -n monitoring

# Activar Prometheus
helm upgrade scan-exporter ./scan-exporter -n monitoring \
  --set podMonitor.enabled=true \
  --set alertRules.enabled=true

# Ver estado
kubectl get pods -n monitoring -l app=scan-exporter
kubectl logs -n monitoring -l app=scan-exporter

# Ver métricas
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112
curl http://localhost:2112/metrics

# Desinstalar
helm uninstall scan-exporter -n monitoring
```

## Estructura del Chart

```
templates/
├── config-map.yaml      → Define targets a escanear
├── deployment.yaml      → Pod y contenedor
├── pod-monitor.yaml     → Integración Prometheus Operator
├── rules.yaml           → Alertas automáticas
├── _helpers.tpl         → Funciones reutilizables
└── NOTES.txt            → Instrucciones post-install
```

## Características

- Monitoreo proactivo con ICMP y TCP
- Exporta métricas Prometheus
- Alertas automáticas configurables
- Health checks continuos
- Soporte multi-replica
- ConfigMap inyectable

## Valores Importantes

```yaml
scanexporter:
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

podMonitor:
  enabled: false        # Activar para Prometheus Operator

alertRules:
  enabled: false        # Activar para alertas automáticas
```

## Troubleshooting

### Pod no inicia
```bash
kubectl describe pod -n monitoring -l app=scan-exporter
kubectl logs -n monitoring -l app=scan-exporter
```

### Sin métricas
```bash
kubectl exec -n monitoring -it deploy/scan-exporter -- \
  curl localhost:2112/metrics
```

### Sin alertas
```bash
kubectl get prometheusrule -n monitoring
kubectl describe prometheusrule -n monitoring scan-exporter
```

## Por Qué Scan-Exporter

Entre 7 opciones disponibles, se eligió porque:

1. Mayor complejidad técnica (6 templates)
2. Valor inmediato en cualquier infraestructura
3. Demuestra Clean Architecture en 3 capas
4. Integración moderna (Prometheus Operator)
5. Altamente extensible

Revisar `POR_QUE_SCAN_EXPORTER.md` para análisis completo.

## Recursos

- Repositorio: https://github.com/Juansex/Helm-charts
- Original: https://github.com/devops-works/helm-charts
- Helm Docs: https://helm.sh/docs/
- Prometheus Operator: https://github.com/prometheus-operator/prometheus-operator

## Información Técnica

```
Chart Version:     2.3.0
App Version:       v2.3.0
Helm:              3.x
Kubernetes:        1.19+
Prometheus:        Soportado (opcional)
Storage:           No requerido
Network:           Solo salida (ICMP/TCP)
Security:          No privilegios requeridos
```

## Próximos Pasos

1. Leer QUICKSTART.md (5 min)
2. Configurar targets en values.yaml
3. Desplegar: `helm install scan-exporter . -n monitoring`
4. Revisar ARQUITECTURA.md para entender profundamente
5. Adaptar EJEMPLOS.md a tu caso de uso

---

Para inicio rápido: **QUICKSTART.md**
Para referencia completa: **README.md**
