# Documentación - Índice de Contenidos

Guía de navegación por la documentación completa de Scan-Exporter Helm Chart.

## Estructura del Repositorio

```
Helm-charts/
├── LICENSE                      # Licencia del proyecto
├── README.md                    # Documentación principal
├── QUICKSTART.md                # Guía de inicio rápido (5 minutos)
├── ARQUITECTURA.md              # Diseño e implementación
├── EJEMPLOS.md                  # Casos de uso y configuraciones
├── POR_QUE_SCAN_EXPORTER.md    # Justificación de selección
│
└── scan-exporter/               # Helm Chart
    ├── Chart.yaml              # Metadatos del chart
    ├── values.yaml             # Valores por defecto
    └── templates/
        ├── _helpers.tpl        # Funciones reutilizables
        ├── NOTES.txt           # Instrucciones post-install
        ├── config-map.yaml     # Configuración de targets
        ├── deployment.yaml     # Pod y contenedor
        ├── pod-monitor.yaml    # Integración Prometheus
        └── rules.yaml          # Alertas automáticas
```

## Guía de Lectura

### 1. Primera Vez (15 minutos)

Leer en este orden:

1. **QUICKSTART.md** - Comienza aquí
   - Prerrequisitos
   - Despliegue en 5 pasos
   - Verificación básica

2. **README.md** - Contextualización
   - Visión general
   - Arquitectura de alto nivel
   - Guía paso a paso

3. **POR_QUE_SCAN_EXPORTER.md** - Entender la decisión
   - Por qué se eligió esta herramienta
   - Comparativa con alternativas
   - Valor agregado

### 2. Profundización Técnica (30 minutos)

Leer estos documentos:

1. **ARQUITECTURA.md** - Diseño detallado
   - Clean Architecture
   - Componentes específicos
   - Patrones implementados
   - Flujo de datos

2. **EJEMPLOS.md** - Aplicaciones prácticas
   - Despliegue básico
   - Infraestructura crítica
   - Multi-región
   - Seguridad mejorada
   - Alta disponibilidad

### 3. Implementación (Según necesidad)

Para desplegar:

1. Editar `scan-exporter/values.yaml`
2. Ejecutar comandos de instalación
3. Validar con troubleshooting si es necesario

## Por Documento

### README.md

**Propósito**: Documentación principal y completa

**Contiene**:
- Visión general de Scan-Exporter
- Arquitectura en capas
- Guía de despliegue paso a paso
- Configuración avanzada
- Ejemplos de comandos
- Troubleshooting
- Referencias

**Ideal para**: Entender qué hace y cómo usarlo

**Tiempo de lectura**: 15 minutos

---

### QUICKSTART.md

**Propósito**: Puesta en marcha rápida

**Contiene**:
- Verificación de prerrequisitos
- 5 pasos de despliegue
- Verificación de estado
- Próximos pasos
- Links a documentación adicional

**Ideal para**: Usuarios con prisa que quieren resultados

**Tiempo de lectura**: 5 minutos

---

### ARQUITECTURA.md

**Propósito**: Entender el diseño técnico

**Contiene**:
- Principios de Clean Architecture
- Separación de responsabilidades
- Explicación de cada componente
- Flujo de datos completo
- Patrones implementados
- Extensibilidad
- Consideraciones de seguridad
- Validación y testing

**Ideal para**: Desarrolladores y DevOps que quieren entender profundamente

**Tiempo de lectura**: 20 minutos

---

### EJEMPLOS.md

**Propósito**: Implementaciones reales

**Contiene**:
- Despliegue básico
- Monitoreo de infraestructura crítica
- Monitoreo multi-región
- Despliegue con seguridad mejorada
- Despliegue con alta disponibilidad
- ConfigMap auto-reload
- Comandos útiles
- Debugging

**Ideal para**: Casos específicos de tu infraestructura

**Tiempo de lectura**: 15 minutos (skim) / 30 minutos (lectura completa)

---

### POR_QUE_SCAN_EXPORTER.md

**Propósito**: Justificación de la elección

**Contiene**:
- Análisis de alternativas
- Criterios de selección
- Ventajas técnicas
- Ventajas de negocio
- Ventajas educativas
- Comparativa detallada
- Escenarios derivados

**Ideal para**: Entender por qué se eligió esta herramienta

**Tiempo de lectura**: 10 minutos

---

## Flujos de Trabajo

### Workflow 1: "Quiero desplegar YA"

```
1. QUICKSTART.md (5 min)
   └─> Completar los 5 pasos

2. Validar con kubectl get pods

3. Consultar README.md si algo falla
```

### Workflow 2: "Quiero aprender la arquitectura"

```
1. README.md (15 min)
   └─> Entender componentes

2. ARQUITECTURA.md (20 min)
   └─> Profundizar en diseño

3. Revisar templates en scan-exporter/templates/

4. EJEMPLOS.md (skim, 10 min)
   └─> Ver casos reales
```

### Workflow 3: "Tengo un caso específico"

```
1. README.md - "Configuración Avanzada" (5 min)

2. EJEMPLOS.md - Buscar caso similar (5 min)

3. Adaptar configuración a tu caso

4. Desplegar y validar
```

### Workflow 4: "Quiero entender por qué esto en lugar de otra cosa"

```
1. POR_QUE_SCAN_EXPORTER.md (10 min)
   └─> Análisis comparativo

2. ARQUITECTURA.md (20 min)
   └─> Entender beneficios técnicos

3. README.md (15 min)
   └─> Ver valor de negocio
```

## Búsqueda Rápida

### Busco: "Cómo desplegar"
→ QUICKSTART.md

### Busco: "Cómo configurar targets"
→ README.md - Sección "Paso 2: Configurar Targets"

### Busco: "Cómo activar alertas"
→ README.md - Sección "Configurar Alertas"

### Busco: "Cómo implementar multi-región"
→ EJEMPLOS.md - Sección "3. Monitoreo Multi-Región"

### Busco: "Por qué no CyberChef"
→ POR_QUE_SCAN_EXPORTER.md

### Busco: "Entender Clean Architecture"
→ ARQUITECTURA.md

### Busco: "Troubleshooting"
→ README.md - Sección "Troubleshooting"

### Busco: "Comandos útiles"
→ EJEMPLOS.md - Sección "Comandos Útiles"

## Información de Referencia

### Links Importantes

- [Repositorio Original](https://github.com/devops-works/helm-charts)
- [Documentación Helm](https://helm.sh/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)

### Valores por Defecto

Documentados en: `scan-exporter/values.yaml`

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
```

### Componentes Generados

- 1 Deployment
- 1 ConfigMap
- 1 PodMonitor (condicional)
- 1 PrometheusRule (condicional)

### Puertos

- Contenedor: 2112 (métricas Prometheus)
- Service: 2112 (mapeo directo)

### Namespaces

Soporta despliegue en cualquier namespace:

```bash
helm install scan-exporter . -n monitoring
helm install scan-exporter . -n observability
helm install scan-exporter . -n default
```

## Mantenimiento de Documentación

Esta documentación está estructurada de forma que:

1. README.md es el documento principal
2. Otros documentos son especializaciones
3. QUICKSTART.md es el punto de entrada
4. Este índice facilita navegación

Para agregar contenido nuevo:

1. Decidir a qué documento pertenece
2. Mantener estructura y formato
3. Actualizar este índice
4. Hacer commit con mensaje descriptivo

## Control de Versiones

Documentación sincronizada con:

```
Chart Version: 2.3.0
App Version: v2.3.0
Última actualización: 2 de Diciembre de 2024
```

---

**Inicio Recomendado**: QUICKSTART.md si tienes prisa, README.md para comprensión completa.
