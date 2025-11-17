{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb-database.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mongodb-database.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mongodb-database.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mongodb-database.labels" -}}
helm.sh/chart: {{ include "mongodb-database.chart" . }}
{{ include "mongodb-database.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: database
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mongodb-database.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mongodb-database.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "mongodb-database.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "mongodb-database.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Get the password secret name
*/}}
{{- define "mongodb-database.secretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- include "mongodb-database.fullname" . -}}-secret
{{- end -}}
{{- end -}}

{{/*
Return MongoDB connection string
*/}}
{{- define "mongodb-database.connectionString" -}}
{{- if .Values.auth.enabled -}}
mongodb://{{ .Values.auth.username }}:{{ .Values.auth.password }}@{{ include "mongodb-database.fullname" . }}:{{ .Values.service.port }}/{{ .Values.auth.database }}
{{- else -}}
mongodb://{{ include "mongodb-database.fullname" . }}:{{ .Values.service.port }}/{{ .Values.auth.database }}
{{- end -}}
{{- end -}}
