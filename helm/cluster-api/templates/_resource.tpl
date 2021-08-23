{{/* vim: set filetype=mustache: */}}
{{/*
Create a name stem for resource names
When pods for deployments are created they have an additional 16 character
suffix appended, e.g. "-957c9d6ff-pkzgw". Given that Kubernetes allows 63
characters for resource names, the stem is truncated to 47 characters to leave
room for such suffix.
*/}}


{{- define "resource.core.name" -}}
cluster-api-core
{{- end -}}

{{- define "resource.core.networkPolicy.name" -}}
{{- include "resource.core.name" . -}}-network-policy
{{- end -}}

{{- define "resource.core.psp.name" -}}
{{- include "resource.core.name" . -}}-psp
{{- end -}}

{{- define "resource.core.pullSecret.name" -}}
{{- include "resource.core.name" . -}}-pull-secret
{{- end -}}

{{- define "resource.bootstrap.name" -}}
cluster-api-bootstrap
{{- end -}}

{{- define "resource.bootstrap.networkPolicy.name" -}}
{{- include "resource.bootstrap.name" . -}}-network-policy
{{- end -}}

{{- define "resource.bootstrap.psp.name" -}}
{{- include "resource.bootstrap.name" . -}}-psp
{{- end -}}

{{- define "resource.bootstrap.pullSecret.name" -}}
{{- include "resource.bootstrap.name" . -}}-pull-secret
{{- end -}}

{{- define "resource.controlplane.name" -}}
cluster-api-controlplane
{{- end -}}

{{- define "resource.controlplane.networkPolicy.name" -}}
{{- include "resource.controlplane.name" . -}}-network-policy
{{- end -}}

{{- define "resource.controlplane.psp.name" -}}
{{- include "resource.controlplane.name" . -}}-psp
{{- end -}}

{{- define "resource.controlplane.pullSecret.name" -}}
{{- include "resource.controlplane.name" . -}}-pull-secret
{{- end -}}



{{- define "resource.default.namespace" -}}
giantswarm
{{- end -}}

{{- define "resource.app.version" -}}
{{- .Chart.AppVersion | quote -}}
{{- end -}}
