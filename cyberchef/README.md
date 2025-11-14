# CyberChef Helm Chart

Este chart despliega [CyberChef](https://github.com/gchq/CyberChef/) en un cluster de Kubernetes usando Helm.

## ¿Qué es CyberChef?

CyberChef es una aplicación web conocida como "la navaja suiza cibernética" desarrollada por GCHQ. Es una herramienta simple e intuitiva para llevar a cabo operaciones "cibernéticas" complejas dentro del navegador web, como:

- Codificación/decodificación (Base64, Hex, etc.)
- Encriptación/desencriptación
- Compresión/descompresión
- Análisis de datos
- Manipulación de texto
- Y mucho más...

## Instalación

### Instalación básica

```bash
helm install cyberchef ./cyberchef
```

### Instalación con valores personalizados

```bash
helm install cyberchef ./cyberchef --set service.type=NodePort
```

### Instalación con archivo de valores

```bash
helm install cyberchef ./cyberchef -f custom-values.yaml
```

## Configuración

Los siguientes valores pueden ser configurados en `values.yaml`:

| Parámetro | Descripción | Valor por defecto |
|-----------|-------------|-------------------|
| `replicaCount` | Número de réplicas del pod | `1` |
| `image.repository` | Repositorio de la imagen | `mpepping/cyberchef` |
| `image.tag` | Tag de la imagen | `v9.24.7` |
| `image.pullPolicy` | Política de pull de la imagen | `IfNotPresent` |
| `service.type` | Tipo de servicio de Kubernetes | `ClusterIP` |
| `service.port` | Puerto del servicio | `8000` |
| `ingress.enabled` | Habilitar ingress | `false` |
| `resources` | Recursos CPU/memoria | `{}` |

## Acceso a la aplicación

### Usando port-forward

```bash
kubectl port-forward svc/cyberchef 8000:8000
```

Luego accede a: http://localhost:8000

### Usando NodePort

```bash
helm upgrade cyberchef ./cyberchef --set service.type=NodePort
kubectl get svc cyberchef
```

Accede usando: `http://<NODE-IP>:<NODE-PORT>`

### Usando Ingress

Edita `values.yaml` para habilitar ingress:

```yaml
ingress:
  enabled: true
  hosts:
    - cyberchef.example.com
```

## Desinstalación

```bash
helm uninstall cyberchef
```

## Verificación

```bash
# Ver el estado del release
helm status cyberchef

# Ver los pods
kubectl get pods -l app.kubernetes.io/name=cyberchef

# Ver los logs
kubectl logs -l app.kubernetes.io/name=cyberchef
```
