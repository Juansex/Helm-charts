# Repositorio de Helm Charts

Este repositorio contiene una colección de Helm charts para desplegar aplicaciones en Kubernetes de manera sencilla y reproducible.

## ¿Qué es Helm?

**Helm** es el gestor de paquetes para Kubernetes. Funciona de manera similar a `apt` en Ubuntu, `yum` en Red Hat, o `npm` para Node.js, pero específicamente diseñado para gestionar aplicaciones en Kubernetes.

### Conceptos Clave

- **Chart**: Un paquete Helm que contiene toda la información necesaria para desplegar una aplicación en Kubernetes
- **Release**: Una instancia de un chart ejecutándose en un cluster de Kubernetes
- **Repository**: Un lugar donde se almacenan y comparten los charts

## Estructura del Repositorio

```
Helm-charts/
├── README.md           # Este archivo
├── LICENSE             # Licencia GPL-3.0
├── .helmignore         # Archivos a ignorar al empaquetar charts
└── cyberchef/          # Chart de ejemplo para CyberChef
    ├── Chart.yaml      # Metadatos del chart
    ├── values.yaml     # Valores configurables por defecto
    ├── README.md       # Documentación específica del chart
    └── templates/      # Plantillas de Kubernetes
        ├── _helpers.tpl      # Funciones helper de Go templates
        ├── deployment.yaml   # Deployment de Kubernetes
        ├── service.yaml      # Service de Kubernetes
        └── ingress.yaml      # Ingress de Kubernetes (opcional)
```

## Charts Disponibles

### CyberChef

**CyberChef** es una aplicación web conocida como "la navaja suiza cibernética" para análisis de datos, encriptación, codificación, compresión y mucho más.

- **Versión del Chart**: 2.0.1
- **Versión de la Aplicación**: v9.24.7
- **Imagen**: `mpepping/cyberchef:v9.24.7`

Para más detalles, consulta el [README del chart CyberChef](./cyberchef/README.md).

## Prerrequisitos

Antes de usar estos charts, necesitas tener instalado:

1. **Kubernetes**: Un cluster de Kubernetes funcionando
   - Puedes usar Minikube, Kind, Docker Desktop, o un cluster en la nube (GKE, EKS, AKS)
   
2. **kubectl**: La herramienta de línea de comandos de Kubernetes
   ```bash
   # Verificar instalación
   kubectl version --client
   ```

3. **Helm 3.x**: El gestor de paquetes de Kubernetes
   ```bash
   # Verificar instalación
   helm version
   ```

## Instalación de Helm

### En Linux
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### En macOS
```bash
brew install helm
```

### En Windows
```powershell
choco install kubernetes-helm
```

## Uso Básico

### 1. Clonar el Repositorio

```bash
git clone https://github.com/Juansex/Helm-charts.git
cd Helm-charts
```

### 2. Instalar un Chart

```bash
# Sintaxis: helm install [NOMBRE-RELEASE] [RUTA-CHART]
helm install cyberchef ./cyberchef
```

### 3. Verificar la Instalación

```bash
# Listar releases de Helm
helm list

# Ver el estado de los recursos de Kubernetes
kubectl get all
```

### 4. Personalizar la Instalación

Puedes personalizar la instalación usando el flag `--set`:

```bash
helm install cyberchef ./cyberchef \
  --set service.type=NodePort \
  --set replicaCount=2
```

O usando un archivo de valores personalizado:

```bash
# Crear archivo custom-values.yaml
cat > custom-values.yaml <<EOF
replicaCount: 2
service:
  type: NodePort
  port: 8000
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

### 5. Actualizar un Release

```bash
helm upgrade cyberchef ./cyberchef --set replicaCount=3
```

### 6. Desinstalar un Release

```bash
helm uninstall cyberchef
```

## Comandos Útiles de Helm

### Validación y Debugging

```bash
# Validar la sintaxis del chart
helm lint ./cyberchef

# Ver los manifiestos que se generarían (sin instalar)
helm install cyberchef ./cyberchef --dry-run --debug

# Ver los valores configurables de un chart
helm show values ./cyberchef

# Ver toda la información de un chart
helm show all ./cyberchef
```

### Gestión de Releases

```bash
# Ver el historial de un release
helm history cyberchef

# Hacer rollback a una versión anterior
helm rollback cyberchef 1

# Ver el estado de un release
helm status cyberchef

# Ver los valores usados en un release
helm get values cyberchef
```

## Anatomía de un Helm Chart

### Chart.yaml
Contiene los metadatos del chart:
- Nombre y versión del chart
- Versión de la aplicación
- Descripción
- Mantenedores
- Fuentes del código

### values.yaml
Define los valores configurables por defecto. Los usuarios pueden sobrescribir estos valores durante la instalación.

### templates/
Contiene las plantillas de Kubernetes que usan el lenguaje de templates de Go. Helm procesa estas plantillas reemplazando los valores y genera manifiestos de Kubernetes válidos.

#### _helpers.tpl
Define funciones helper reutilizables en las plantillas:
- `cyberchef.name`: Genera el nombre del chart
- `cyberchef.fullname`: Genera el nombre completo del release
- `cyberchef.chart`: Genera el nombre y versión del chart

#### deployment.yaml
Define cómo se despliega la aplicación:
- Número de réplicas
- Imagen del contenedor
- Puertos
- Recursos (CPU/memoria)
- Probes de salud

#### service.yaml
Define cómo se expone la aplicación dentro del cluster:
- Tipo de servicio (ClusterIP, NodePort, LoadBalancer)
- Puertos
- Selectores para conectar con los pods

#### ingress.yaml
Define cómo se expone la aplicación fuera del cluster:
- Reglas de enrutamiento
- TLS/SSL
- Hosts y paths

## Conceptos de Templates

Los templates de Helm usan la sintaxis de Go templates con funciones adicionales de Sprig:

```yaml
# Acceder a valores
{{ .Values.replicaCount }}

# Usar funciones helper
{{ include "cyberchef.fullname" . }}

# Condicionales
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
{{- end }}

# Bucles
{{- range .Values.ingress.hosts }}
  - host: {{ . | quote }}
{{- end }}
```

## Mejores Prácticas

1. **Usa valores sensatos por defecto**: Los valores en `values.yaml` deben permitir que el chart funcione inmediatamente
2. **Documenta todos los valores**: Incluye comentarios explicando cada valor configurable
3. **Usa labels consistentes**: Sigue las convenciones de etiquetado de Kubernetes
4. **Incluye probes de salud**: Define liveness y readiness probes para tus aplicaciones
5. **Valida los charts**: Ejecuta `helm lint` antes de compartir tus charts
6. **Versiona correctamente**: Usa versionado semántico (SemVer)

## Troubleshooting

### El chart no se instala

```bash
# Ver los manifiestos generados
helm install cyberchef ./cyberchef --dry-run --debug

# Ver los logs del pod
kubectl logs -l app.kubernetes.io/name=cyberchef

# Describir el pod para ver eventos
kubectl describe pod -l app.kubernetes.io/name=cyberchef
```

### No puedo acceder a la aplicación

```bash
# Verificar que el service existe
kubectl get svc

# Usar port-forward para acceso local
kubectl port-forward svc/cyberchef 8000:8000
```

### Errores de puerto

Asegúrate de que:
- El `containerPort` en el deployment coincide con el puerto donde escucha la aplicación
- El `targetPort` en el service apunta al mismo puerto
- El `service.port` en values.yaml es el puerto que quieres exponer

## Recursos Adicionales

- [Documentación Oficial de Helm](https://helm.sh/docs/)
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Go Template Documentation](https://pkg.go.dev/text/template)
- [Sprig Template Functions](http://masterminds.github.io/sprig/)

## Contribuir

Si deseas contribuir a este repositorio:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nuevo-chart`)
3. Realiza tus cambios y valídalos con `helm lint`
4. Haz commit de tus cambios (`git commit -am 'Añadir nuevo chart'`)
5. Push a la rama (`git push origin feature/nuevo-chart`)
6. Crea un Pull Request

## Licencia

Este proyecto está licenciado bajo la GNU General Public License v3.0 - ver el archivo [LICENSE](LICENSE) para más detalles.

## Autor

**Juansex**
- GitHub: [@Juansex](https://github.com/Juansex)

## Agradecimientos

- Basado en el trabajo de [cheo-kt/helm-charts](https://github.com/cheo-kt/helm-charts)
- Comunidad de Helm y Kubernetes
- Proyecto CyberChef de GCHQ