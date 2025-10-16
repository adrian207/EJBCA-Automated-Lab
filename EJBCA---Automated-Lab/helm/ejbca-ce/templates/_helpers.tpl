{{/*
Expand the name of the chart.
*/}}
{{- define "ejbca-ce.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ejbca-ce.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ejbca-ce.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ejbca-ce.labels" -}}
helm.sh/chart: {{ include "ejbca-ce.chart" . }}
{{ include "ejbca-ce.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: pki-platform
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ejbca-ce.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ejbca-ce.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ejbca-ce.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ejbca-ce.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database connection string
*/}}
{{- define "ejbca-ce.databaseUrl" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "jdbc:postgresql://%s-postgresql:5432/%s" .Release.Name .Values.postgresql.auth.database }}
{{- else }}
{{- printf "jdbc:postgresql://%s:%d/%s" .Values.externalDatabase.host (.Values.externalDatabase.port | int) .Values.externalDatabase.database }}
{{- end }}
{{- end }}

