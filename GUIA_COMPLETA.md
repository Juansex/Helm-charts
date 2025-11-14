# Guía Completa: Helm Charts desde Cero

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [¿Qué son los Helm Charts?](#qué-son-los-helm-charts)
3. [Estructura de este Repositorio](#estructura-de-este-repositorio)
4. [Explicación Detallada de Cada Archivo](#explicación-detallada-de-cada-archivo)
5. [Cómo Funciona Helm](#cómo-funciona-helm)
6. [Paso a Paso: Creando un Chart](#paso-a-paso-creando-un-chart)
7. [Mejores Prácticas](#mejores-prácticas)
8. [Ejemplos de Uso](#ejemplos-de-uso)

---

## Introducción

Este repositorio contiene Helm charts para desplegar aplicaciones en Kubernetes. Fue creado como un ejemplo educativo completo para entender cómo funcionan los Helm charts desde cero.

**Objetivo**: Proporcionar una base sólida para entender y crear Helm charts, utilizando CyberChef como ejemplo práctico.

---

## ¿Qué son los Helm Charts?

### Analogía Simple

Piensa en Helm como un "gestor de paquetes para Kubernetes", similar a:
- **apt** en Ubuntu (instala software)
- **npm** en Node.js (instala librerías)
- **pip** en Python (instala paquetes)

Pero en lugar de instalar software en tu computadora, Helm instala **aplicaciones completas** en un cluster de Kubernetes.

### Componentes Principales

1. **Chart**: Un paquete que contiene:
   - Plantillas de recursos de Kubernetes
   - Valores configurables
   - Metadatos de la aplicación

2. **Release**: Una instancia instalada de un chart en tu cluster

3. **Values**: Los valores de configuración que personalizan tu instalación

---

## Estructura de este Repositorio

```
Helm-charts/
│
├── README.md              # Documentación principal del repositorio
├── GUIA_COMPLETA.md      # Este archivo - Guía educativa detallada
├── LICENSE               # Licencia GPL-3.0
├── .helmignore           # Archivos que Helm debe ignorar
│
└── cyberchef/            # Chart de ejemplo: CyberChef
    ├── Chart.yaml        # Metadatos del chart
    ├── values.yaml       # Valores configurables por defecto
    ├── README.md         # Documentación del chart
    └── templates/        # Plantillas de Kubernetes
        ├── _helpers.tpl      # Funciones helper reutilizables
        ├── deployment.yaml   # Define cómo se despliega la app
        ├── service.yaml      # Define cómo se expone la app
        └── ingress.yaml      # Define acceso externo (opcional)
```

---

## Explicación Detallada de Cada Archivo

### 1. Chart.yaml

**Propósito**: Define los metadatos del chart.

```yaml
apiVersion: v1                    # Versión de la API de Helm
appVersion: "v9.24.7"            # Versión de la aplicación que despliega
description: A Helm chart for...  # Descripción del chart
name: cyberchef                   # Nombre del chart (único)
version: 2.0.1                    # Versión del chart (SemVer)
home: https://...                 # URL del proyecto
maintainers:                      # Quién mantiene este chart
  - name: devopsworks
    email: support@devops.works
```

**Puntos Clave**:
- `version`: Versión del chart (incrementa cuando cambias el chart)
- `appVersion`: Versión de la aplicación que instala el chart
- Son independientes: puedes actualizar el chart (2.0.1 → 2.0.2) sin cambiar la versión de la app

### 2. values.yaml

**Propósito**: Define todos los valores que los usuarios pueden personalizar.

```yaml
replicaCount: 1              # ¿Cuántas copias del pod?

image:
  repository: mpepping/cyberchef  # ¿Qué imagen usar?
  tag: v9.24.7                     # ¿Qué versión?
  pullPolicy: IfNotPresent         # ¿Cuándo descargar la imagen?

service:
  type: ClusterIP              # Tipo de servicio Kubernetes
  port: 8000                   # Puerto a exponer

ingress:
  enabled: false               # ¿Exponer fuera del cluster?

resources: {}                  # Límites de CPU/RAM
```

**Por qué es importante**:
- Los usuarios pueden sobrescribir CUALQUIER valor sin editar las plantillas
- Proporciona valores sensatos por defecto
- Documenta todas las opciones de configuración

### 3. templates/_helpers.tpl

**Propósito**: Define funciones reutilizables para las plantillas.

```yaml
{{- define "cyberchef.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
```

**Qué hace**:
1. Define una función llamada `cyberchef.name`
2. Usa el nombre del chart, pero permite sobrescribirlo
3. Lo trunca a 63 caracteres (límite de Kubernetes)
4. Elimina guiones al final

**Cómo se usa**:
```yaml
name: {{ include "cyberchef.name" . }}
```

### 4. templates/deployment.yaml

**Propósito**: Define cómo Kubernetes debe ejecutar tu aplicación.

```yaml
apiVersion: apps/v1
kind: Deployment                        # Tipo de recurso
metadata:
  name: {{ include "cyberchef.fullname" . }}  # Nombre dinámico
  labels:
    app.kubernetes.io/name: {{ include "cyberchef.name" . }}
spec:
  replicas: {{ .Values.replicaCount }}  # Cuántas copias
  selector:
    matchLabels:                        # Cómo encontrar los pods
      app.kubernetes.io/name: {{ include "cyberchef.name" . }}
  template:
    metadata:
      labels:                           # Labels para los pods
        app.kubernetes.io/name: {{ include "cyberchef.name" . }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - name: http
              containerPort: 8000       # Puerto del contenedor
          livenessProbe:                # ¿Está vivo el contenedor?
            httpGet:
              path: /
              port: http
          resources:
{{ toYaml .Values.resources | indent 12 }}
```

**Conceptos Clave**:

- **Replicas**: Cuántas copias de la aplicación ejecutar
- **Selector**: Cómo Kubernetes identifica los pods de este deployment
- **Container**: La imagen Docker a ejecutar
- **Ports**: Qué puerto expone el contenedor
- **LivenessProbe**: Comprueba si la app está funcionando

### 5. templates/service.yaml

**Propósito**: Define cómo otros pods (o usuarios) acceden a tu aplicación.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "cyberchef.fullname" . }}
spec:
  type: {{ .Values.service.type }}      # ClusterIP, NodePort, LoadBalancer
  ports:
    - port: {{ .Values.service.port }}  # Puerto del servicio
      targetPort: http                  # Puerto del contenedor
      protocol: TCP
      name: http
  selector:                             # Qué pods usar
    app.kubernetes.io/name: {{ include "cyberchef.name" . }}
```

**Tipos de Service**:

1. **ClusterIP** (default):
   - Solo accesible dentro del cluster
   - Ideal para servicios internos

2. **NodePort**:
   - Accesible desde fuera en `<NodeIP>:<NodePort>`
   - Útil para desarrollo

3. **LoadBalancer**:
   - Crea un balanceador de carga externo
   - Ideal para producción en la nube

### 6. templates/ingress.yaml

**Propósito**: Define reglas de enrutamiento HTTP/HTTPS desde fuera del cluster.

```yaml
{{- if .Values.ingress.enabled -}}     # Solo si está habilitado
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $fullName }}
spec:
  rules:
  {{- range .Values.ingress.hosts }}
    - host: {{ . | quote }}             # Nombre de dominio
      http:
        paths:
          - path: {{ $ingressPath }}
            backend:
              service:
                name: {{ $fullName }}
                port:
                  number: 8000
  {{- end }}
{{- end }}
```

**Cuándo usar Ingress**:
- Quieres acceso HTTP/HTTPS desde internet
- Necesitas SSL/TLS
- Quieres enrutamiento basado en dominio

### 7. .helmignore

**Propósito**: Lista archivos que Helm debe ignorar al empaquetar el chart.

```
.DS_Store
.git/
.gitignore
*.swp
.idea/
.vscode/
```

Similar a `.gitignore` pero para Helm.

---

## Cómo Funciona Helm

### Proceso de Instalación

```
1. Usuario ejecuta: helm install myapp ./cyberchef

2. Helm lee Chart.yaml y values.yaml

3. Helm procesa las plantillas en templates/
   - Reemplaza {{ .Values.* }} con valores reales
   - Ejecuta funciones de _helpers.tpl
   - Genera manifiestos de Kubernetes válidos

4. Helm envía los manifiestos a Kubernetes

5. Kubernetes crea los recursos:
   - Deployment → crea Pods
   - Service → crea endpoints
   - Ingress → configura enrutamiento

6. Helm guarda información del release
```

### Sistema de Templates

Helm usa **Go templates** con funciones adicionales de **Sprig**.

**Sintaxis Básica**:

```yaml
# Acceder a valores
{{ .Values.replicaCount }}

# Condicionales
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
{{- end }}

# Bucles
{{- range .Values.ingress.hosts }}
  - host: {{ . | quote }}
{{- end }}

# Funciones
{{ include "cyberchef.name" . }}

# Pipes (encadenar funciones)
{{ .Values.name | upper | quote }}
```

**El punto (.)**: Representa el contexto actual, que incluye:
- `.Values`: Valores de values.yaml
- `.Chart`: Información de Chart.yaml
- `.Release`: Información del release (nombre, namespace, etc.)

---

## Paso a Paso: Creando un Chart

### Método 1: Usar helm create (Rápido)

```bash
helm create mi-aplicacion
```

Esto genera un chart básico que puedes personalizar.

### Método 2: Desde Cero (Educativo)

**Paso 1: Crear estructura**
```bash
mkdir -p mi-app/templates
cd mi-app
```

**Paso 2: Crear Chart.yaml**
```yaml
apiVersion: v1
name: mi-app
version: 0.1.0
appVersion: "1.0"
description: Mi primera aplicación Helm
```

**Paso 3: Crear values.yaml**
```yaml
replicaCount: 1
image:
  repository: nginx
  tag: latest
service:
  port: 80
```

**Paso 4: Crear templates/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: app
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        ports:
        - containerPort: 80
```

**Paso 5: Validar**
```bash
helm lint .
helm template . | kubectl apply --dry-run=client -f -
```

**Paso 6: Instalar**
```bash
helm install mi-release .
```

---

## Mejores Prácticas

### 1. Nombrado

✅ **Bien**:
```yaml
name: {{ include "myapp.fullname" . }}
```

❌ **Mal**:
```yaml
name: myapp
```

**Por qué**: Permite múltiples instalaciones del mismo chart.

### 2. Labels Consistentes

Usa las labels recomendadas de Kubernetes:
```yaml
labels:
  app.kubernetes.io/name: {{ include "myapp.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
```

### 3. Valores Sensatos por Defecto

```yaml
# ✅ Bien: funciona out-of-the-box
service:
  type: ClusterIP
  port: 8000

# ❌ Mal: requiere configuración
service:
  type: ""
  port: null
```

### 4. Documentación

- Comenta cada valor en values.yaml
- Incluye ejemplos en README.md
- Explica cambios importantes en Chart.yaml

### 5. Versionado

Usa **Semantic Versioning**:
- `1.0.0` → `1.0.1`: Bug fixes
- `1.0.0` → `1.1.0`: Nuevas features (compatible)
- `1.0.0` → `2.0.0`: Cambios incompatibles

---

## Ejemplos de Uso

### Ejemplo 1: Instalación Básica

```bash
# Instalar con valores por defecto
helm install cyberchef ./cyberchef

# Verificar
kubectl get pods
kubectl get svc
```

### Ejemplo 2: Personalización en Línea

```bash
helm install cyberchef ./cyberchef \
  --set replicaCount=3 \
  --set service.type=NodePort \
  --set service.port=9000
```

### Ejemplo 3: Personalización con Archivo

```bash
# Crear archivo de valores personalizados
cat > custom-values.yaml <<EOF
replicaCount: 2

image:
  tag: v10.0.0

service:
  type: LoadBalancer
  port: 8080

ingress:
  enabled: true
  hosts:
    - cyberchef.midominio.com

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
EOF

# Instalar con valores personalizados
helm install cyberchef ./cyberchef -f custom-values.yaml
```

### Ejemplo 4: Actualización

```bash
# Actualizar la aplicación
helm upgrade cyberchef ./cyberchef --set image.tag=v10.1.0

# Ver historial
helm history cyberchef

# Rollback si algo sale mal
helm rollback cyberchef 1
```

### Ejemplo 5: Debugging

```bash
# Ver qué manifiestos se generarían
helm template cyberchef ./cyberchef

# Instalar en modo debug
helm install cyberchef ./cyberchef --debug --dry-run

# Ver valores finales aplicados
helm get values cyberchef

# Ver todos los manifiestos instalados
helm get manifest cyberchef
```

---

## Conclusión

Este repositorio demuestra:

1. ✅ **Estructura completa** de un repositorio de Helm charts
2. ✅ **Chart funcional** (CyberChef) listo para usar
3. ✅ **Documentación exhaustiva** en español
4. ✅ **Mejores prácticas** aplicadas
5. ✅ **Ejemplos prácticos** de uso

### Próximos Pasos

1. Instala el chart en tu cluster local (Minikube/Kind)
2. Personaliza los valores según tus necesidades
3. Crea tus propios charts siguiendo esta estructura
4. Comparte tus charts con la comunidad

### Recursos Adicionales

- [Documentación Oficial de Helm](https://helm.sh/docs/)
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Go Templates](https://pkg.go.dev/text/template)
- [Sprig Functions](http://masterminds.github.io/sprig/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Autor**: Juansex  
**Licencia**: GPL-3.0  
**Basado en**: [cheo-kt/helm-charts](https://github.com/cheo-kt/helm-charts)
