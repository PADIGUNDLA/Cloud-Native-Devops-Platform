{{/*
Expand the name of the chart.
*/}}
{{- define "devops-dashboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the fully qualified application name.
Use the Helm release name so Jenkins can manage the existing release resources.
*/}}
{{- define "devops-dashboard.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "devops-dashboard.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "devops-dashboard.selectorLabels" . }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "devops-dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "devops-dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the service account name.
*/}}
{{- define "devops-dashboard.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "devops-dashboard.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
