{{- define "mm-events.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mm-events.fullname" -}}
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

{{- define "mm-events.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "mm-events.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels; call with (dict "root" $ "component" "backend") */}}
{{- define "mm-events.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mm-events.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "mm-events.backendName" -}}
{{- printf "%s-backend" (include "mm-events.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mm-events.frontendName" -}}
{{- printf "%s-frontend" (include "mm-events.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mm-events.backendServiceAccountName" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (include "mm-events.backendName" .) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "mm-events.secretName" -}}
{{- default (include "mm-events.backendName" .) .Values.secrets.name }}
{{- end }}

{{- define "mm-events.image" -}}
{{- if not .image.repository }}
{{- fail (printf "%s.image.repository is required" .component) }}
{{- end }}
{{- printf "%s:%s" .image.repository (toString .image.tag) }}
{{- end }}

{{/* Service annotations: the configured ones plus the GKE BackendConfig link when enabled.
     Call with (dict "root" $ "name" <service name> "annotations" <map>) */}}
{{- define "mm-events.serviceAnnotations" -}}
{{- $a := deepCopy (default (dict) .annotations) -}}
{{- if .root.Values.gkeBackendConfig.enabled }}
{{- $_ := set $a "cloud.google.com/backend-config" (printf "{\"default\": \"%s\"}" .name) -}}
{{- $_ := set $a "cloud.google.com/neg" "{\"ingress\": true}" -}}
{{- end }}
{{- if $a }}
{{- toYaml $a }}
{{- end }}
{{- end }}
