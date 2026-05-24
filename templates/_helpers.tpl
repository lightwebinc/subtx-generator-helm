{{- define "bitcoin-subtx-generator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bitcoin-subtx-generator.fullname" -}}
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

{{- define "bitcoin-subtx-generator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "bitcoin-subtx-generator.labels" -}}
helm.sh/chart: {{ include "bitcoin-subtx-generator.chart" . }}
{{ include "bitcoin-subtx-generator.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: bitcoin-multicast
app.kubernetes.io/component: {{ .Values.mode }}
{{- end -}}

{{- define "bitcoin-subtx-generator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bitcoin-subtx-generator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "bitcoin-subtx-generator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "bitcoin-subtx-generator.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "bitcoin-subtx-generator.multusAnnotation" -}}
{{- if eq .Values.networking.mode "multus" -}}
k8s.v1.cni.cncf.io/networks: |
  [{
    "name": {{ .Values.networking.multus.networkName | quote }},
    "namespace": {{ .Values.networking.multus.namespace | quote }},
    {{- if .Values.networking.multus.fabricIPv6 }}
    "ips": [ {{ .Values.networking.multus.fabricIPv6 | quote }} ],
    {{- end }}
    "interface": {{ .Values.networking.multus.interface | quote }}
  }]
{{- end -}}
{{- end -}}

{{/*
emitFlag — render a single CLI flag, honoring zero/empty defaults.
Receives a dict with keys:
  name: the kebab-case flag (without leading dash)
  v:    the value (any type)
- bool true  → "-<name>"
- bool false → omitted
- empty string / "0s" → omitted
- string / number / duration → "-<name>=<value>"
- 0 numeric → omitted (binary default applies)
*/}}
{{- define "bitcoin-subtx-generator.emitFlag" -}}
{{- $name := .name -}}
{{- $v := .v -}}
{{- if kindIs "bool" $v -}}
{{- if $v }}
- {{ printf "-%s" $name }}
{{- end -}}
{{- else if kindIs "string" $v -}}
{{- if and (ne $v "") (ne $v "0s") }}
- {{ printf "-%s=%v" $name $v }}
{{- end -}}
{{- else -}}
{{- if and $v (ne (printf "%v" $v) "0") }}
- {{ printf "-%s=%v" $name $v }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Container args (rendered as a YAML list) for the selected mode.
Each (camelCase values key) → (kebab-case binary flag) mapping is explicit
to avoid relying on regex backreference behaviour across Sprig versions.
*/}}
{{- define "bitcoin-subtx-generator.args" -}}
{{/* Shared flags */}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "addr" "v" .Values.args.addr) -}}
{{- if eq .Values.mode "subtx-gen" -}}
{{- $a := .Values.subtxGen -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "frame-version"         "v" $a.frameVersion) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "shard-bits"            "v" $a.shardBits) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "subtrees"              "v" $a.subtrees) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "subtree-seed"          "v" $a.subtreeSeed) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "pps"                   "v" $a.pps) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "duration"              "v" $a.duration) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "count"                 "v" $a.count) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "workers"               "v" $a.workers) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "payload-size"          "v" $a.payloadSize) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "payload-format"        "v" $a.payloadFormat) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "seq-start"             "v" $a.seqStart) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "seq-gap-every"         "v" $a.seqGapEvery) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "seq-gap-size"          "v" $a.seqGapSize) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "seq-gap-delay"         "v" $a.seqGapDelay) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "log-interval"          "v" $a.logInterval) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "print-subtrees"        "v" $a.printSubtrees) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "subtree-group"         "v" $a.subtreeGroup) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "announce-addr"         "v" $a.announceAddr) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "announce-interval"     "v" $a.announceInterval) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "announce-ttl"          "v" $a.announceTtl) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "announce-phase-size"   "v" $a.announcePhaseSize) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "announce-phase-interval" "v" $a.announcePhaseInterval) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "corrupt-txid-rate"     "v" $a.corruptTxidRate) -}}
{{- else if eq .Values.mode "send-anchor-frame" -}}
{{- $a := .Values.sendAnchorFrame -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "count"        "v" $a.count) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "payload-size" "v" $a.payloadSize) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "interval"     "v" $a.interval) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "tcp"          "v" $a.tcp) -}}
{{- else if eq .Values.mode "send-block-announce" -}}
{{- $a := .Values.sendBlockAnnounce -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "blocks"   "v" $a.blocks) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "subtrees" "v" $a.subtrees) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "interval" "v" $a.interval) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "coinbase" "v" $a.coinbase) -}}
{{- else if eq .Values.mode "send-subtree-data" -}}
{{- $a := .Values.sendSubtreeData -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "frames"        "v" $a.frames) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "msg-type"      "v" $a.msgType) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "nodes"         "v" $a.nodes) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "payload-size"  "v" $a.payloadSize) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "subtree-count" "v" $a.subtreeCount) -}}
{{- include "bitcoin-subtx-generator.emitFlag" (dict "name" "interval"      "v" $a.interval) -}}
{{- end -}}
{{- end -}}

{{/*
Shared pod spec body.
*/}}
{{- define "bitcoin-subtx-generator.podSpec" -}}
serviceAccountName: {{ include "bitcoin-subtx-generator.serviceAccountName" . }}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if eq .Values.networking.mode "host" }}
hostNetwork: true
dnsPolicy: {{ .Values.networking.host.dnsPolicy }}
{{- end }}
{{- with .Values.priorityClassName }}
priorityClassName: {{ . }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if eq .Values.workloadType "Job" }}
restartPolicy: OnFailure
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- with .Values.securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    command: ["/{{ .Values.mode }}"]
    args:
      {{- include "bitcoin-subtx-generator.args" . | nindent 6 }}
    {{- with .Values.extraEnv }}
    env:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
