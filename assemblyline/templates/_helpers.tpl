{{ define "assemblyline.coreEnv" }}
- name: ELASTIC_ALERT_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-alert-shards
- name: ELASTIC_DEFAULT_REPLICAS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-default-replicas
- name: ELASTIC_DEFAULT_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-default-shards
- name: ELASTIC_EMPTYRESULT_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-emptyresult-shards
- name: ELASTIC_FILE_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-file-shards
- name: ELASTIC_FILESCORE_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-filescore-shards
- name: ELASTIC_RESULT_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-result-shards
- name: ELASTIC_SAFELIST_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-safelist-shards
- name: ELASTIC_SUBMISSION_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-submission-shards
- name: LOGGING_PASSWORD
  valueFrom:
    secretKeyRef:
      name: assemblyline-system-passwords
      key: logging-password
- name: LOGGING_HOST
  valueFrom:
    configMapKeyRef:
      name: system-settings
      key: logging-host
- name: LOGGING_USERNAME
  valueFrom:
    configMapKeyRef:
      name: system-settings
      key: logging-username
- name: ELASTIC_PASSWORD
  valueFrom:
    secretKeyRef:
      name: assemblyline-system-passwords
      key: datastore-password
- name: RETROHUNT_API_KEY
  valueFrom:
    secretKeyRef:
      name: retrohunt-secret
      key: password
- name: ENABLE_INTERNAL_ENCRYPTION
  value: {{ if .Values.enableInternalEncryption }}"true"{{else}}"false"{{end}}
- name: DISPATCHER_RESULT_THREADS
  value: "{{ .Values.dispatcherResultThreads }}"
- name: DISPATCHER_FINALIZE_THREADS
  value: "{{ .Values.dispatcherFinalizeThreads }}"
- name: DEV_MODE
  value: "{{ .Values.enableCoreDebugging | default false | toString }}"
{{ if .Values.internalFilestore }}
- name: INTERNAL_FILESTORE_ACCESS
  valueFrom:
    secretKeyRef:
      name: internal-filestore-keys
      key: accesskey
- name: INTERNAL_FILESTORE_KEY
  valueFrom:
    secretKeyRef:
      name: internal-filestore-keys
      key: secretkey
{{ else }}
- name: FILESTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: assemblyline-system-passwords
      key: filestore-password
- name: IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
{{ end }}
{{ if .Values.coreEnv }}
{{- .Values.coreEnv | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.nodeAffinity" }}
{{ if .Values.nodeAffinity }}
{{- .Values.nodeAffinity | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.tolerations" }}
{{ if .Values.tolerations }}
{{- .Values.tolerations | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreLabels" }}
{{ if .Values.coreLabels }}
{{- .Values.coreLabels | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreSecurityContext" }}
{{ if .Values.coreSecurityContext }}
{{- .Values.coreSecurityContext | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreMounts" }}
- name: al-config
  mountPath: /etc/assemblyline/config.yml
  subPath: config
  readOnly: true
{{ if .Values.useReplay }}
- name: replay-config
  mountPath: /etc/assemblyline/replay.yml
  subPath: replay
  readOnly: true
{{ end }}
{{ if .Values.enableInternalEncryption }}
- name: root-cert
  mountPath: "/etc/assemblyline/ssl/al_root-ca.crt"
  subPath: tls.crt
  readOnly: true
{{ end }}
{{ if .Values.coreMounts }}
{{- .Values.coreMounts | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreVolumes" }}
- name: al-config
  configMap:
    name: {{ .Release.Name }}-global-config
{{ if .Values.useReplay }}
- name: replay-config
  configMap:
    name: {{ .Release.Name }}-replay-config
{{ end }}
{{ if .Values.enableInternalEncryption }}
- name: root-cert
  secret:
    secretName: {{ .Release.Name }}.internal-generated-ca
{{ end }}
{{ if .Values.coreVolumes }}
{{- .Values.coreVolumes | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.replayVolume" }}
{{ if and .replayContainer (eq .Values.replayMode "loader") }}
{{- .Values.replayLoaderVolume | toYaml -}}
{{ end}}
{{end}}
---
{{ define "assemblyline.coreService" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .component }}
  labels:
    app: assemblyline
    section: core
    component: {{ .component }}
spec:
  replicas: {{ .replicas | default 1 }}
  revisionHistoryLimit: {{ .Values.revisionCount }}
  selector:
    matchLabels:
      app: assemblyline
      section: core
      component: {{ .component }}
  template:
    metadata:
      annotations:
        checksum/config: {{ .Values.configuration | toYaml | sha256sum }}
      labels:
        app: assemblyline
        section: core
        component: {{ .component }}
        {{ include "assemblyline.coreLabels" . | indent 8 }}
    spec:
      priorityClassName: al-core-priority
      serviceAccountName: {{ .Values.coreServiceAccountName }}
      terminationGracePeriodSeconds: {{ .terminationSeconds | default 60 }}
      affinity:
        nodeAffinity:
          {{ include "assemblyline.nodeAffinity" . | indent 10 }}
      tolerations:
        {{ include "assemblyline.tolerations" . | indent 8 }}
      containers:
        - name: {{ .component }}
          image: {{ .image | default .Values.assemblylineCoreImage }}:{{ .Values.release }}
          imagePullPolicy: {{ .Values.imagePullPolicy }}
          securityContext:
            {{ include "assemblyline.coreSecurityContext" . | indent 12 }}
            runAsUser: {{ .runAsUser | default 1000}}
            runAsGroup: 1000
          {{ if .Values.enableCoreDebugging}}
          command: ['python', '-m', 'debugpy', '--listen', 'localhost:5678', '-m', '{{ .command }}']
          {{ else }}
          command: ['python', '-m', '{{ .command }}']
          {{ end}}
          volumeMounts:
          {{ if and .replayContainer (eq .Values.replayMode "loader") }}
            - name: replay-data
              mountPath: {{ .Values.replay.loader.input_directory }}
          {{ end}}
          {{ include "assemblyline.coreMounts" . | indent 12 }}
          {{ if .mounts }}
          {{ .mounts | toYaml | nindent 12 }}
          {{ end }}
          resources:
            requests:
              memory: {{ .requestedRam | default .Values.defaultReqRam }}
              cpu: {{ .requestedCPU | default .Values.defaultReqCPU }}
            limits:
              memory: {{ .limitRam | default .Values.defaultLimRam }}
              cpu: {{ .limitCPU | default .Values.defaultLimCPU  }}
          env:
          {{ include "assemblyline.coreEnv" . | indent 12 }}
            - name: AL_SHUTDOWN_GRACE
              value: "{{ .terminationSeconds | default 60 }}"
          livenessProbe:
            exec:
              command:
               - bash
               - "-c"
               - {{ .livenessCommand | default "if [[ ! `find /tmp/heartbeat -newermt '-30 seconds'` ]]; then false; fi" }}
            initialDelaySeconds: 30
            periodSeconds: 30
      volumes:
      {{ include "assemblyline.replayVolume" . | indent 8 }}
      {{ include "assemblyline.coreVolumes" . | indent 8 }}
      {{ if .volumes }}
      {{ .volumes | toYaml | nindent 8 }}
      {{ end }}
{{ end }}
---
{{ define "assemblyline.coreServiceNoCheck" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .component }}
  labels:
    app: assemblyline
    section: core
    component: {{ .component }}
spec:
  replicas: {{ .replicas | default 1 }}
  revisionHistoryLimit: {{ .Values.revisionCount }}
  selector:
    matchLabels:
      app: assemblyline
      section: core
      component: {{ .component }}
  template:
    metadata:
      annotations:
        checksum/config: {{ .Values.configuration | toYaml | sha256sum }}
      labels:
        app: assemblyline
        section: core
        component: {{ .component }}
        {{ include "assemblyline.coreLabels" . | indent 8 }}
    spec:
      priorityClassName: al-core-priority
      serviceAccountName: {{ .Values.coreServiceAccountName }}
      terminationGracePeriodSeconds: {{ .terminationSeconds | default 60 }}
      affinity:
        nodeAffinity:
          {{ include "assemblyline.nodeAffinity" . | indent 10 }}
      tolerations:
        {{ include "assemblyline.tolerations" . | indent 8 }}
      containers:
        - name: {{ .component }}
          image: {{ .Values.assemblylineCoreImage }}:{{ .Values.release }}
          imagePullPolicy: {{ .Values.imagePullPolicy }}
          securityContext:
            {{ include "assemblyline.coreSecurityContext" . | indent 12 }}
            runAsUser: {{ .runAsUser | default 1000}}
            runAsGroup: 1000
          command: ['python', '-m', '{{ .command }}']
          volumeMounts:
          {{ include "assemblyline.coreMounts" . | indent 12 }}
          {{ if .mounts }}
          {{ .mounts | toYaml | nindent 12 }}
          {{ end }}
          resources:
            requests:
              memory: {{ .requestedRam | default .Values.defaultReqRam }}
              cpu: {{ .requestedCPU | default .Values.defaultReqCPU }}
            limits:
              memory: {{ .limitRam | default .Values.defaultLimRam }}
              cpu: {{ .limitCPU | default .Values.defaultLimCPU  }}
          env:
          {{ include "assemblyline.coreEnv" . | indent 12 }}
            - name: AL_SHUTDOWN_GRACE
              value: "{{ .terminationSeconds | default 60 }}"
      volumes:
      {{ include "assemblyline.coreVolumes" . | indent 8 }}
      {{ if .volumes }}
      {{ .volumes | toYaml | nindent 8 }}
      {{ end }}
{{ end }}
---
{{ define "assemblyline.HPA" }}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: {{.name}}-hpa
spec:
  maxReplicas: {{int .maxReplicas}}
  minReplicas: {{int .minReplicas}}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{.name}}
  targetCPUUtilizationPercentage: {{.targetUsage}}
{{ end }}
---
{{ define "assemblyline.InternalCertificates" }}
# Store CA
{{ $ca := .ca }}
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: {{ .Release.Name }}.internal-generated-ca
  labels:
    app: assembyline
data:
  tls.crt: {{ b64enc $ca.Cert }}
  tls.key: {{ b64enc $ca.Key }}
---
# Create signed certificates for hosts specified in values.yaml
{{ $hosts := list "service-server" "ui" "socketio" "frontend" "dispatcher" "ingester" "plumber" "redis-persistent" "redis-volatile" "logstash" "filestore" "kibana" "apm" (print .Values.datastore.clusterName "-master") (print (get (get .Values "log-storage") "clusterName") "-master") }}
{{ if .Values.configuration.retrohunt.enabled }}
  {{ $hosts = append $hosts "hauntedhouse" }}
  {{ $hosts = append $hosts "hauntedhouse-worker" }}
{{ end }}
{{ range $host := $hosts }}
{{ $server_sec := lookup "v1" "Secret" $.Release.Namespace "{{ $host }}-cert" }}
{{ if $server_sec }}
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: {{ $host }}-cert
  labels:
    app: assembyline
data:
  tls.crt: {{ get $server_sec.data "tls.crt" }}
  tls.key: {{ get $server_sec.data "tls.key" }}
---
{{ else }}
{{ $server := genSignedCert $host nil (list $host) 36500 $ca}}
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: {{ $host }}-cert
  labels:
    app: assembyline
data:
  tls.crt: {{ (b64enc $server.Cert) }}
  tls.key: {{ (b64enc $server.Key) }}
---
{{ end }}
{{ end }}
{{ end }}
---
{{ define "assemblyline.rustService" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .component }}
  labels:
    app: assemblyline
    section: core
    component: {{ .component }}
spec:
  replicas: {{ .replicas | default 1 }}
  revisionHistoryLimit: {{ .Values.revisionCount }}
  selector:
    matchLabels:
      app: assemblyline
      section: core
      component: {{ .component }}
  template:
    metadata:
      annotations:
        checksum/config: {{ .Values.configuration | toYaml | sha256sum }}
      labels:
        app: assemblyline
        section: core
        component: {{ .component }}
        {{ include "assemblyline.coreLabels" . | indent 8 }}
    spec:
      priorityClassName: al-core-priority
      serviceAccountName: {{ .Values.coreServiceAccountName }}
      #setHostnameAsFQDN: true
      #subdomain: {{ .component }}
      terminationGracePeriodSeconds: {{ .terminationSeconds | default 60 }}
      affinity:
        nodeAffinity:
          {{ include "assemblyline.nodeAffinity" . | indent 10 }}
      tolerations:
        {{ include "assemblyline.tolerations" . | indent 8 }}
      containers:
        - name: {{ .component }}
          image: {{ .image | default .Values.assemblylineRustImage }}:{{ .Values.release }}
          imagePullPolicy: {{ .Values.imagePullPolicy }}
          securityContext:
            {{ include "assemblyline.coreSecurityContext" . | indent 12 }}
            runAsUser: {{ .runAsUser | default 1000}}
            runAsGroup: 1000
          {{ if .Values.enableCoreDebugging}}
          command: ['{{ .command }}', {{if .Values.enableInternalEncryption }}'--secure-connections',{{end}} '{{ .component }}']
          {{ else }}
          command: ['{{ .command }}', {{if .Values.enableInternalEncryption }}'--secure-connections',{{end}} '{{ .component }}']
          {{ end}}
          volumeMounts:
          {{ if and .replayContainer (eq .Values.replayMode "loader") }}
            - name: replay-data
              mountPath: {{ .Values.replay.loader.input_directory }}
          {{ end}}
          {{ include "assemblyline.coreMounts" . | indent 12 }}
          {{ if .mounts }}
          {{ .mounts | toYaml | nindent 12 }}
          {{ end }}
          {{if .Values.enableInternalEncryption }}
            - name: server-cert
              mountPath: /etc/assemblyline/ssl/server
          {{ end }}
          resources:
            requests:
              memory: {{ .requestedRam | default .Values.defaultReqRam }}
              cpu: {{ .requestedCPU | default .Values.defaultReqCPU }}
            limits:
              memory: {{ .limitRam | default .Values.defaultLimRam }}
              cpu: {{ .limitCPU | default .Values.defaultLimCPU  }}
          env:
            # Don't actually need the flask key for core containers, but since the variable is 
            # used in the config file it needs to be initialized
            - name: FLASK_SECRET_KEY
              value: ""
          {{ include "assemblyline.coreEnv" . | indent 12 }}
            - name: AL_SHUTDOWN_GRACE
              value: "{{ .terminationSeconds | default 60 }}"
          {{ if .Values.enableInternalEncryption }}
            - name: SERVER_CERT_PATH
              value: /etc/assemblyline/ssl/server/tls.crt
            - name: SERVER_KEY_PATH
              value: /etc/assemblyline/ssl/server/tls.key
            - name: SSL_CERT_FILE
              value: /etc/assemblyline/ssl/al_root-ca.crt
          {{ end}}
          livenessProbe:
            httpGet:
              scheme: HTTPS
              path: /alive
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 30
      volumes:
      {{ include "assemblyline.replayVolume" . | indent 8 }}
      {{ include "assemblyline.coreVolumes" . | indent 8 }}
      {{ if .volumes }}
      {{ .volumes | toYaml | nindent 8 }}
      {{ end }}
      {{if .Values.enableInternalEncryption }}
        - name: server-cert
          secret:
            secretName: {{ .component }}-cert
      {{ end }}
{{ end }}
