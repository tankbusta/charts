{{/*
Expand the name of the chart.
*/}}
{{- define "ghidra-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ghidra-server.fullname" -}}
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
{{- define "ghidra-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ghidra-server.labels" -}}
helm.sh/chart: {{ include "ghidra-server.chart" . }}
{{ include "ghidra-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ghidra-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghidra-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ghidra-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ghidra-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Hostname Ghidra hands to clients for its RMI ports (-ip).
Defaults to the in-cluster Service name.
*/}}
{{- define "ghidra-server.hostname" -}}
{{- .Values.server.hostname | default (printf "%s.%s.svc.%s" (include "ghidra-server.fullname" .) .Release.Namespace .Values.clusterDomain) }}
{{- end }}

{{/*
Name of the Secret holding the panel's jaas.conf
*/}}
{{- define "ghidra-server.jaasSecretName" -}}
{{- .Values.panel.existingSecret | default (printf "%s-jaas" (include "ghidra-server.fullname" .)) }}
{{- end }}

{{/*
Jars downloaded by the plugin installer: the panel jar (when enabled) followed by .Values.plugins
*/}}
{{- define "ghidra-server.plugins" -}}
{{- $plugins := list }}
{{- if .Values.panel.enabled }}
{{- $plugins = append $plugins (dict "name" "ghidra-panel" "url" .Values.panel.jar.url "sha256" .Values.panel.jar.sha256) }}
{{- end }}
{{- $plugins = concat $plugins .Values.plugins }}
{{- toJson $plugins }}
{{- end }}

{{/*
Fail early on configurations the server would refuse to start with
*/}}
{{- define "ghidra-server.validate" -}}
{{- $names := dict }}
{{- range (include "ghidra-server.plugins" . | fromJsonArray) }}
{{- if not (regexMatch "^[A-Za-z0-9][A-Za-z0-9_.-]*$" (.name | default "")) }}
{{- fail (printf "plugin name %q must be alphanumeric, with optional '_', '.' or '-'" (.name | default "")) }}
{{- end }}
{{- if hasKey $names .name }}
{{- fail (printf "duplicate plugin name %q" .name) }}
{{- end }}
{{- $_ := set $names .name true }}
{{- if not .url }}
{{- fail (printf "plugin %q is missing url" .name) }}
{{- end }}
{{- end }}
{{- if and .Values.panel.enabled (not .Values.panel.existingSecret) (not .Values.panel.jdbc) }}
{{- fail "panel.enabled requires panel.jdbc or panel.existingSecret" }}
{{- end }}
{{- if .Values.tlsRoute.enabled }}
{{- if not .Values.tlsRoute.parentRef.name }}
{{- fail "tlsRoute.enabled requires tlsRoute.parentRef.name" }}
{{- end }}
{{- if not (or .Values.tlsRoute.hostnames .Values.server.hostname) }}
{{- fail "tlsRoute.enabled requires server.hostname or tlsRoute.hostnames, since routing is by SNI" }}
{{- end }}
{{- end }}
{{- if .Values.tls.enabled }}
{{- if not (has .Values.tls.format (list "pkcs12" "pem")) }}
{{- fail (printf "tls.format must be pkcs12 or pem, got %q" .Values.tls.format) }}
{{- end }}
{{- if .Values.tls.certManager.enabled }}
{{- if not .Values.tls.certManager.issuerRef.name }}
{{- fail "tls.certManager.enabled requires tls.certManager.issuerRef.name" }}
{{- end }}
{{- else }}
{{- if not .Values.tls.secretName }}
{{- fail "tls.enabled without tls.certManager.enabled requires tls.secretName" }}
{{- end }}
{{- if and (eq .Values.tls.format "pkcs12") (not .Values.tls.passwordSecret.name) }}
{{- fail "tls.format pkcs12 without tls.certManager.enabled requires tls.passwordSecret.name" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding the TLS keystore
*/}}
{{- define "ghidra-server.tlsSecretName" -}}
{{- .Values.tls.secretName | default (printf "%s-tls" (include "ghidra-server.fullname" .)) }}
{{- end }}

{{/*
Keystore file name under /ghidra/server/tls
*/}}
{{- define "ghidra-server.keystoreFile" -}}
{{- if eq .Values.tls.format "pem" }}keystore.p12{{ else }}{{ .Values.tls.keystoreKey }}{{ end }}
{{- end }}

{{/*
Whether the chart generates the keystore password
*/}}
{{- define "ghidra-server.generateKeystorePassword" -}}
{{- if and .Values.tls.enabled (not .Values.tls.passwordSecret.name) (or .Values.tls.certManager.enabled (eq .Values.tls.format "pem")) }}true{{ end }}
{{- end }}

{{/*
Name of the Secret holding the TLS keystore password
*/}}
{{- define "ghidra-server.tlsPasswordSecretName" -}}
{{- .Values.tls.passwordSecret.name | default (printf "%s-keystore-password" (include "ghidra-server.fullname" .)) }}
{{- end }}
