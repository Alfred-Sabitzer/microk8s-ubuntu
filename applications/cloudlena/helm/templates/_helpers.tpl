{{- define "cloudlena.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudlena.fullname" -}}
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

{{- define "cloudlena.labels" -}}
app: {{ .Release.Name }}
digest: {{ .Values.image.digest | quote }}
app.kubernetes.io/name: {{ include "cloudlena.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "cloudlena.annotations" -}}
build.tool: {{ .Values.buildInfo.tool | quote }}
build.tag: {{ .Values.image.tag | quote }}
build.project: {{ .Values.image.project | quote }}
build.image: {{ .Values.image.repository | quote }}
build.registry: {{ .Values.image.registry | quote }}
{{- end -}}

{{- define "cloudlena.SelectorLabels" -}}
app: {{ .Release.Name }}
digest: {{ .Values.image.digest | quote }}
{{- end -}}
