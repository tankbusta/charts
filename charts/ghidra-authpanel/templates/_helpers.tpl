{{/*
Expand the name of the chart.
*/}}
{{- define "ghidra-authpanel.name" -}}
{{- default .Chart.Name .Values.nameOverride | replace "_" "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ghidra-authpanel.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride | replace "_" "-" }}
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
{{- define "ghidra-authpanel.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ghidra-authpanel.labels" -}}
helm.sh/chart: {{ include "ghidra-authpanel.chart" . }}
{{ include "ghidra-authpanel.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ghidra-authpanel.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghidra-authpanel.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ghidra-authpanel.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ghidra-authpanel.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding ghidra_panel.secrets.json
*/}}
{{- define "ghidra-authpanel.hmacSecretName" -}}
{{- .Values.hmacSecret.existingSecret | default (printf "%s-hmac" (include "ghidra-authpanel.fullname" .)) }}
{{- end }}

{{/*
Fail early on configurations the panel would refuse to start with
*/}}
{{- define "ghidra-authpanel.validate" -}}
{{- $discord := .Values.config.discord | default dict }}
{{- $oidc := .Values.config.oidc | default dict }}
{{- if not (or $discord.client_id $oidc.issuer) }}
{{- fail "no login provider configured, set config.discord.client_id or config.oidc.issuer" }}
{{- end }}
{{- if not .Values.config.base_url }}
{{- fail "config.base_url is required" }}
{{- end }}
{{- end }}
