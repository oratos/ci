CLUSTER_NAME="oratos-vault"
CLUSTER_SIZE=3
CLUSTER_ZONE=us-central1-a
CLUSTER_VERSION=1.10
NAMESPACE_NAME="$CLUSTER_NAME"
LASTPASS_VAULT_GCS_SERVICE_ACCOUNT="Shared-CF-Oratos/service account for vault GCS"
LASTPASS_X509_PATH="Shared-CF-Oratos/vault.oratos.ci.cf-app.com certs/key"
VALUES="
vault:
  dev: false
  customSecrets:
  - secretName: vault-gcs-service-account
    mountPath: /vault/sa
  extraEnv:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: /vault/sa/key.json
  config:
    api_addr: "https://vault.oratos.ci.cf-app.com"
    storage:
      gcs:
        bucket: oratos-ci-vault
        ha_enabled: \"true\"
"
