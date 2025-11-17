# Helm Charts Repository

Repositorio de Helm charts para desplegar aplicaciones en Kubernetes de forma estandarizada y reproducible.

## Contenido

Este repositorio contiene los siguientes charts:

- **nginx-app**: Servidor web Nginx con configuracion personalizable para aplicaciones web estaticas.
- **redis-cache**: Sistema de cache y base de datos en memoria Redis con persistencia y metricas.
- **mongodb-database**: Base de datos NoSQL MongoDB con soporte para persistencia, autenticacion y metricas.

## Requisitos Previos

- Kubernetes cluster (version 1.19+)
- Helm 3.x instalado
- kubectl configurado y autenticado con el cluster
- Acceso a imagenes de contenedores desde Docker Hub

## Instalacion

### Nginx Application

Servidor web Nginx ligero y configurable para servir contenido estatico.

#### Instalacion Basica

```bash
helm install mi-nginx ./nginx-app
```

#### Instalacion Personalizada

```bash
helm install mi-nginx ./nginx-app \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

#### Con archivo de valores personalizado

```bash
helm install mi-nginx ./nginx-app --values mi-configuracion.yaml
```

#### Verificar el Despliegue

```bash
kubectl get pods -l app.kubernetes.io/name=nginx-app
kubectl get svc -l app.kubernetes.io/name=nginx-app
kubectl get deployments
```

#### Acceder a la Aplicacion

Para servicio tipo ClusterIP (por defecto):

```bash
export POD_NAME=$(kubectl get pods -l "app.kubernetes.io/name=nginx-app" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080
```

Accede a http://127.0.0.1:8080 en tu navegador.

### Redis Cache

Sistema de cache en memoria con persistencia opcional y soporte para metricas.

#### Instalacion Basica

```bash
helm install mi-redis ./redis-cache
```

#### Instalacion con Persistencia

```bash
helm install mi-redis ./redis-cache \
  --set persistence.enabled=true \
  --set persistence.size=10Gi
```

#### Instalacion con Metricas

```bash
helm install mi-redis ./redis-cache \
  --set metrics.enabled=true \
  --set auth.password="mi-password-seguro"
```

#### Conectarse a Redis

```bash
# Obtener password
export REDIS_PASSWORD=$(kubectl get secret mi-redis-redis-cache-secret -o jsonpath="{.data.password}" | base64 -d)

# Conectar usando cliente
kubectl run redis-client --rm -i --tty --restart='Never' \
  --image redis:7.2.3-alpine \
  -- redis-cli -h mi-redis-redis-cache -a $REDIS_PASSWORD
```

### MongoDB Database

Base de datos NoSQL orientada a documentos con alta disponibilidad y escalabilidad.

#### Instalacion Basica

```bash
helm install mi-mongodb ./mongodb-database
```

#### Instalacion con Autenticacion

```bash
helm install mi-mongodb ./mongodb-database \
  --set auth.enabled=true \
  --set auth.rootPassword="mi-password-root" \
  --set auth.password="mi-password-usuario"
```

#### Instalacion con Persistencia y Metricas

```bash
helm install mi-mongodb ./mongodb-database \
  --set persistence.enabled=true \
  --set persistence.size=20Gi \
  --set metrics.enabled=true
```

#### Conectarse a MongoDB

```bash
# Obtener password de root
export MONGODB_ROOT_PASSWORD=$(kubectl get secret mi-mongodb-mongodb-database-secret -o jsonpath="{.data.mongodb-root-password}" | base64 -d)

# Conectar usando cliente
kubectl run mongodb-client --rm -i --tty --restart='Never' \
  --image mongo:7.0.4 \
  --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" \
  -- mongosh admin --host mi-mongodb-mongodb-database \
     --authenticationDatabase admin -u admin -p $MONGODB_ROOT_PASSWORD
```

## Configuracion

### Nginx Application - Valores Principales

#### Imagen y Replicas

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.25.3-alpine"
  pullPolicy: IfNotPresent
```

#### Servicio

```yaml
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
```

Tipos de servicio soportados:
- `ClusterIP`: Acceso interno al cluster (por defecto)
- `NodePort`: Expone el servicio en un puerto del nodo
- `LoadBalancer`: Usa un balanceador de carga externo

#### Ingress

Habilitar acceso externo mediante Ingress Controller:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: mi-app.ejemplo.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: mi-app-tls
      hosts:
        - mi-app.ejemplo.com
```

#### Contenido Personalizado

Personalizar el contenido HTML servido:

```yaml
configMap:
  enabled: true
  data:
    index.html: |
      <!DOCTYPE html>
      <html>
      <head><title>Mi Aplicacion</title></head>
      <body><h1>Hola Mundo</h1></body>
      </html>
```

#### Recursos

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

#### Autoescalado

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 75
  targetMemoryUtilizationPercentage: 80
```

#### Persistencia

Para almacenamiento persistente:

```yaml
persistence:
  enabled: true
  storageClass: "standard"
  accessMode: ReadWriteOnce
  size: 1Gi
  mountPath: /usr/share/nginx/html
```

### Redis Cache - Valores Principales

#### Imagen y Configuracion Basica

```yaml
replicaCount: 1

image:
  repository: redis
  tag: "7.2.3-alpine"
  pullPolicy: IfNotPresent
```

#### Autenticacion

```yaml
auth:
  enabled: true
  password: "tu-password-seguro"
  # O usar un secret existente
  existingSecret: "mi-redis-secret"
  existingSecretPasswordKey: "password"
```

#### Configuracion de Redis

```yaml
config:
  maxmemory: "256mb"
  maxmemoryPolicy: "allkeys-lru"
  appendonly: "yes"
  appendfsync: "everysec"
  saveEnabled: true
  save: "900 1 300 10 60 10000"
```

Politicas de maxmemory disponibles:
- `allkeys-lru`: Elimina las claves menos usadas recientemente
- `allkeys-lfu`: Elimina las claves menos frecuentemente usadas
- `volatile-lru`: Elimina claves con TTL, menos usadas
- `volatile-ttl`: Elimina claves con TTL mas corto
- `noeviction`: No elimina claves, retorna error

#### Persistencia

```yaml
persistence:
  enabled: true
  storageClass: "standard"
  accessMode: ReadWriteOnce
  size: 8Gi
  mountPath: /data
```

#### Metricas con Prometheus

```yaml
metrics:
  enabled: true
  image:
    repository: oliver006/redis_exporter
    tag: "v1.55.0"
  port: 9121
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi
```

#### Recursos

```yaml
resources:
  limits:
    cpu: 300m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
```

#### Seguridad

```yaml
podSecurityContext:
  fsGroup: 999
  runAsNonRoot: true
  runAsUser: 999

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: false
```

### MongoDB Database - Valores Principales

#### Imagen y Configuracion Basica

```yaml
replicaCount: 1
architecture: standalone

image:
  repository: mongo
  tag: "7.0.4"
  pullPolicy: IfNotPresent
```

#### Autenticacion

```yaml
auth:
  enabled: true
  rootUser: "admin"
  rootPassword: "mongodb-root-password"
  database: "myapp"
  username: "appuser"
  password: "mongodb-user-password"
  # O usar un secret existente
  existingSecret: ""
```

#### Configuracion de MongoDB

```yaml
config:
  enableJournal: true
  storageEngine: "wiredTiger"
  wiredTiger:
    engineCacheSizeGB: 0.5
  verbosity: 0
  operationProfiling:
    mode: "off"
    slowOpThresholdMs: 100
```

Modos de profiling disponibles:
- `off`: Sin profiling
- `slowOp`: Solo operaciones lentas
- `all`: Todas las operaciones

#### Persistencia

```yaml
persistence:
  enabled: true
  storageClass: "standard"
  accessMode: ReadWriteOnce
  size: 10Gi
  mountPath: /data/db
```

#### Metricas con Prometheus

```yaml
metrics:
  enabled: true
  image:
    repository: percona/mongodb_exporter
    tag: "0.40.0"
  port: 9216
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 64Mi
```

#### Scripts de Inicializacion

Ejecutar scripts al inicializar la base de datos:

```yaml
initdb:
  enabled: true
  scripts:
    init-db.js: |
      db = db.getSiblingDB('myapp');
      db.createCollection('users');
      db.users.insertOne({
        name: 'admin',
        role: 'administrator'
      });
```

#### Recursos

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

#### Seguridad

```yaml
podSecurityContext:
  fsGroup: 999
  runAsNonRoot: true
  runAsUser: 999

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: false
```

## Comandos Utiles de Helm

### Gestion de Releases

#### Listar releases instalados

```bash
helm list
helm list --all-namespaces
```

#### Ver estado de un release

```bash
helm status mi-nginx
helm status mi-redis
helm status mi-mongodb
```

#### Ver historial de revisiones

```bash
helm history mi-nginx
```

#### Actualizar un release

```bash
helm upgrade mi-nginx ./nginx-app --values mi-config.yaml
helm upgrade mi-redis ./redis-cache --set persistence.size=20Gi
```

#### Actualizar o instalar (upgrade/install)

```bash
helm upgrade --install mi-nginx ./nginx-app
```

#### Rollback a version anterior

```bash
helm rollback mi-nginx 1
```

#### Desinstalar un release

```bash
helm uninstall mi-nginx
helm uninstall mi-redis --keep-history
```

### Validacion y Pruebas

#### Validar templates sin instalar

```bash
helm template mi-nginx ./nginx-app
helm template mi-redis ./redis-cache --values test-values.yaml
helm template mi-mongodb ./mongodb-database
```

#### Dry-run para ver que se crearia

```bash
helm install --dry-run --debug mi-nginx ./nginx-app
```

#### Validar sintaxis del chart

```bash
helm lint ./nginx-app
helm lint ./redis-cache
helm lint ./mongodb-database
```

### Gestion de Valores

#### Ver valores por defecto

```bash
helm show values ./nginx-app
helm show values ./redis-cache
helm show values ./mongodb-database
```

#### Ver valores de un release instalado

```bash
helm get values mi-nginx
helm get values mi-redis
```

#### Ver todos los detalles de un release

```bash
helm get all mi-nginx
```

### Empaquetado

#### Empaquetar un chart

```bash
helm package ./nginx-app
helm package ./redis-cache
helm package ./mongodb-database
```

#### Ver dependencias

```bash
helm dependency list ./nginx-app
```

## Estructura de los Charts

### Nginx Application

```
nginx-app/
├── Chart.yaml              # Metadatos del chart
├── values.yaml             # Valores por defecto
└── templates/              # Templates de Kubernetes
    ├── _helpers.tpl        # Funciones helper
    ├── deployment.yaml     # Deployment principal
    ├── service.yaml        # Servicio
    ├── serviceaccount.yaml # Service Account
    ├── configmap.yaml      # ConfigMap para contenido
    ├── pvc.yaml           # PersistentVolumeClaim
    ├── ingress.yaml        # Ingress (condicional)
    ├── hpa.yaml           # HorizontalPodAutoscaler (condicional)
    └── NOTES.txt          # Instrucciones post-instalacion
```

### Redis Cache

```
redis-cache/
├── Chart.yaml              # Metadatos del chart
├── values.yaml             # Valores por defecto
└── templates/              # Templates de Kubernetes
    ├── _helpers.tpl        # Funciones helper
    ├── statefulset.yaml    # StatefulSet para Redis
    ├── service.yaml        # Servicios (normal y headless)
    ├── serviceaccount.yaml # Service Account
    ├── configmap.yaml      # Configuracion de Redis
    ├── secret.yaml         # Secret para password
    ├── pvc.yaml           # PersistentVolumeClaim
    └── NOTES.txt          # Instrucciones post-instalacion
```

### MongoDB Database

```
mongodb-database/
├── Chart.yaml              # Metadatos del chart
├── values.yaml             # Valores por defecto
└── templates/              # Templates de Kubernetes
    ├── _helpers.tpl        # Funciones helper
    ├── statefulset.yaml    # StatefulSet para MongoDB
    ├── service.yaml        # Servicios (normal y headless)
    ├── serviceaccount.yaml # Service Account
    ├── configmap.yaml      # Configuracion de MongoDB
    ├── configmap-initdb.yaml # Scripts de inicializacion
    ├── secret.yaml         # Secrets para passwords
    └── NOTES.txt          # Instrucciones post-instalacion
```

## Ejemplos de Uso

### Nginx con Ingress y TLS

```yaml
# nginx-prod-values.yaml
replicaCount: 3

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: app.midominio.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.midominio.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Desplegar:

```bash
helm install mi-app ./nginx-app -f nginx-prod-values.yaml
```

### Redis con Persistencia y Metricas

```yaml
# redis-prod-values.yaml
auth:
  enabled: true
  password: "password-super-seguro-cambiar"

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 20Gi

config:
  maxmemory: "2gb"
  maxmemoryPolicy: "allkeys-lru"
  saveEnabled: true

metrics:
  enabled: true

resources:
  limits:
    cpu: 500m
    memory: 2Gi
  requests:
    cpu: 250m
    memory: 1Gi
```

Desplegar:

```bash
helm install cache-prod ./redis-cache -f redis-prod-values.yaml
```

### MongoDB con Replica Set y Backups

```yaml
# mongodb-prod-values.yaml
architecture: replicaset
replicaCount: 3

auth:
  enabled: true
  rootPassword: "password-root-seguro"
  password: "password-app-seguro"
  database: "production"

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 50Gi

config:
  enableJournal: true
  wiredTiger:
    engineCacheSizeGB: 2

backup:
  enabled: true
  schedule: "0 2 * * *"
  retention: 14

metrics:
  enabled: true

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi

initdb:
  enabled: true
  scripts:
    setup.js: |
      db = db.getSiblingDB('production');
      db.createCollection('users');
      db.createCollection('logs');
```

Desplegar:

```bash
helm install db-prod ./mongodb-database -f mongodb-prod-values.yaml
```

## Troubleshooting

### Verificar estado de pods

```bash
kubectl get pods -l app.kubernetes.io/name=nginx-app
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Ver eventos del cluster

```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Verificar configuracion aplicada

```bash
helm get manifest mi-nginx
kubectl get configmap <configmap-name> -o yaml
```

### Problemas comunes

#### Pod en estado CrashLoopBackOff

```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

#### PVC en estado Pending

```bash
kubectl get pvc
kubectl describe pvc <pvc-name>
# Verificar que exista un StorageClass disponible
kubectl get storageclass
```

#### Servicio no accesible

```bash
kubectl get svc
kubectl get endpoints
# Verificar que los pods esten en estado Running
kubectl get pods
```

## Buenas Practicas

1. **Versionado**: Siempre especifica la version de la imagen en production
2. **Recursos**: Define limits y requests apropiados para tus pods
3. **Seguridad**: Habilita security contexts y usa usuarios no-root
4. **Backups**: Para Redis con persistencia, implementa estrategia de backup
5. **Monitoring**: Habilita metricas y monitoreo en produccion
6. **Secretos**: Nunca incluyas passwords en values.yaml, usa secrets externos
7. **Testing**: Usa `--dry-run` y `helm test` antes de desplegar en produccion

## Contribuciones

Para reportar problemas o sugerir mejoras, utiliza el sistema de issues del repositorio.

## Licencia

Este proyecto esta licenciado bajo la GNU General Public License v3.0.