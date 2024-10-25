{{/*
Expand the name of the chart.
*/}}
{{- define "metrics-logs-python-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

