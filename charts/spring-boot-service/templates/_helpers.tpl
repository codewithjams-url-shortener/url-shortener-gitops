{{/*
Chart name, used as a label value and container name.
*/}}
{{- define "spring-boot-service.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resource name prefix. Each service is installed as its own Release of this chart, so the
Release name alone (e.g. "url-service") is already a unique, meaningful resource name —
no need to combine it with the chart name the way a multi-instance-per-release chart would.
*/}}
{{- define "spring-boot-service.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "spring-boot-service.labels" -}}
app.kubernetes.io/name: {{ include "spring-boot-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Selector labels — a stable subset of the common labels, since Deployment/Service selectors
are immutable and must not change across chart upgrades.
*/}}
{{- define "spring-boot-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spring-boot-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name to use, honoring serviceAccount.name when set.
*/}}
{{- define "spring-boot-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "spring-boot-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
