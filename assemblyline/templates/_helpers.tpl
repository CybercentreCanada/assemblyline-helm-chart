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
- name: ELASTIC_RESULT_SHARDS
  valueFrom:
    configMapKeyRef:
      name: elasticsearch-indexes
      key: elastic-result-shards
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
- name: DISPATCHER_RESULT_THREADS
  value: "{{ .Values.dispatcherResultThreads }}"
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
{{ end }}
{{ if .Values.coreEnv }}
{{- .Values.coreEnv | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreMounts" }}
- name: al-config
  mountPath: /etc/assemblyline/config.yml
  subPath: config
{{ if .Values.coreMounts }}
{{- .Values.coreMounts | toYaml -}}
{{ end }}
{{ end }}
---
{{ define "assemblyline.coreVolumes" }}
- name: al-config
  configMap:
    name: {{ .Release.Name }}-global-config
{{ if .Values.coreVolumes }}
{{- .Values.coreVolumes | toYaml -}}
{{ end }}
{{ end }}
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
      labels:
        app: assemblyline
        section: core
        component: {{ .component }}
    spec:
      priorityClassName: al-core-priority
      containers:
        - name: {{ .component }}
          image: {{ .Values.assemblylineCoreImage }}:{{ .Values.release }}
          imagePullPolicy: Always
          {{ if .Values.enableCoreDebugging}}
          command: ['python', '-m', 'debugpy', '--listen', 'localhost:5678', '-m', '{{ .command }}']
          {{ else }}
          command: ['python', '-m', '{{ .command }}']
          {{ end}}

          volumeMounts:
          {{ include "assemblyline.coreMounts" . | indent 12 }}
          resources:
            requests:
              memory: {{ .requestedRam | default .Values.defaultReqRam }}
              cpu: {{ .requestedCPU | default .Values.defaultReqCPU }}
            limits:
              memory: 1Gi
              cpu: 1
          env:
          {{ include "assemblyline.coreEnv" . | indent 12 }}
          livenessProbe:
            exec:
              command: ["bash", "-c", "if [[ ! `find /tmp/heartbeat -newermt '-30 seconds'` ]]; then false; fi"]
            initialDelaySeconds: 30
            periodSeconds: 30
      volumes:
      {{ include "assemblyline.coreVolumes" . | indent 8 }}
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
      labels:
        app: assemblyline
        section: core
        component: {{ .component }}
    spec:
      priorityClassName: al-core-priority
      containers:
        - name: {{ .component }}
          image: {{ .Values.assemblylineCoreImage }}:{{ .Values.release }}
          imagePullPolicy: Always
          command: ['python', '-m', '{{ .command }}']
          volumeMounts:
          {{ include "assemblyline.coreMounts" . | indent 12 }}
          resources:
            requests:
              memory: {{ .requestedRam | default .Values.defaultReqRam }}
              cpu: {{ .requestedCPU | default .Values.defaultReqCPU }}
            limits:
              memory: 1Gi
              cpu: 1
          env:
          {{ include "assemblyline.coreEnv" . | indent 12 }}
      volumes:
      {{ include "assemblyline.coreVolumes" . | indent 8 }}
{{ end }}
