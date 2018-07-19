CLUSTER_NAME="oratos-vault"
CLUSTER_SIZE=3
CLUSTER_ZONE=us-central1-a
CLUSTER_VERSION=1.10
NAMESPACE_NAME="$CLUSTER_NAME"
LASTPASS_VAULT_GCS_SERVICE_ACCOUNT="Shared-CF-Oratos/service account for vault GCS"
LASTPASS_X509_PATH="Shared-CF-Oratos/vault.oratos.ci.cf-app.com certs/key"
VALUES="
service:
  type: NodePort
ingress:
  enabled: true
  hosts:
  - vault.oratos.ci.cf-app.com
  annotations:
    kubernetes.io/ingress.allow-http: false
  tls:
  - hosts:
    - vault.oratos.ci.cf-app.com
    secretName: vault-tls
vault:
  dev: false
  customSecrets:
  - secretName: vault-gcs-service-account
    mountPath: /vault/sa
  config:
    api_addr: "https://vault.oratos.ci.cf-app.com"
    storage:
      gcs:
        bucket: oratos-ci-vault
        ha_enabled: \"true\"
        credentials_file: /vault/sa/key.json
"
