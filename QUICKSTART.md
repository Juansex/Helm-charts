# Guía de Inicio Rápido

Comienza a usar Scan-Exporter en 5 minutos.

## Prerrequisitos

```bash
# Verificar Helm
helm version

# Verificar kubectl
kubectl cluster-info

# Verificar acceso al cluster
kubectl auth can-i create deployments --namespace default
```

## 1. Descargar el Repositorio

```bash
git clone https://github.com/Juansex/Helm-charts.git
cd Helm-charts/scan-exporter
```

## 2. Crear Namespace

```bash
kubectl create namespace monitoring
```

## 3. Configuración Básica

Editar el archivo `values.yaml` y actualizar `targets` con tus servidores:

```yaml
targets: |-
  timeout: 2
  limit: 1024
  targets:
    - name: "mi-servidor"
      ip: "192.168.1.100"
      tcp:
        period: "10s"
        range: "reserved"
        expected: "22,443"
      icmp:
        period: "30s"
```

## 4. Desplegar

```bash
helm install scan-exporter . -n monitoring
```

## 5. Verificar Estado

```bash
# Esperar a que el pod esté running
kubectl get pods -n monitoring

# Ver logs
kubectl logs -n monitoring -f deployment/scan-exporter

# Acceder a métricas
kubectl port-forward -n monitoring svc/scan-exporter 2112:2112

# En otra terminal:
curl http://localhost:2112/metrics
```

## Próximos Pasos

### Integrar con Prometheus

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set podMonitor.enabled=true
```

### Agregar Alertas

```bash
helm upgrade scan-exporter . \
  -n monitoring \
  --set alertRules.enabled=true \
  --set alertRules.namespace=monitoring
```

### Monitoreo Avanzado

Ver `EJEMPLOS.md` para configuraciones más complejas.

## Troubleshooting

### Pod no inicia

```bash
kubectl describe pod -n monitoring -l app=scan-exporter
kubectl logs -n monitoring -l app=scan-exporter
```

### No hay métricas

```bash
# Verificar que el endpoint esté accesible
kubectl exec -n monitoring -it deploy/scan-exporter -- curl localhost:2112/metrics
```

### Alertas no funcionan

```bash
# Verificar PrometheusRule
kubectl get prometheusrule -n monitoring
kubectl describe prometheusrule -n monitoring scan-exporter
```

## Más Información

- [README.md](README.md) - Documentación completa
- [ARQUITECTURA.md](ARQUITECTURA.md) - Detalles de diseño
- [EJEMPLOS.md](EJEMPLOS.md) - Casos de uso avanzados
