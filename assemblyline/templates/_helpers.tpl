{{ define "assemblyline.coreEnv" }}
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
- name: FILESTORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: assemblyline-system-passwords
      key: filestore-password
{{ if .Values.coreEnv }}
{{- .Values.coreEnv | toYaml -}}
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
  replicas: 1
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
          image: cccs/assemblyline-core:{{ .Values.coreVersion }}
          imagePullPolicy: Always
          command: ['python', '-m', '{{ .command }}']
          volumeMounts:
            - name: al-config
              mountPath: /etc/assemblyline/
          resources:
            requests:
              memory: 128Mi
              cpu: 0.05
            limits:
              memory: 1Gi
              cpu: 1
          env:
          {{ include "assemblyline.coreEnv" . | indent 12 }}
      volumes:
        - name: al-config
          configMap:
            name: {{ .Release.Name }}-global-config
            items:
              - key: config
                path: config.yml
              - key: classification
                path: classification.yml
{{ end }}

