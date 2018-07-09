#!/bin/bash
PROJECT_NAME=oratos
CLUSTER_NAME="${PROJECT_NAME}-ci"
# shellcheck disable=SC2034
CLUSTER_SIZE=6
# shellcheck disable=SC2034
CLUSTER_ZONE=us-central1-a
# shellcheck disable=SC2034
CLUSTER_VERSION=1.10
# shellcheck disable=SC2034
NAMESPACE_NAME="$CLUSTER_NAME"
# shellcheck disable=SC2034
LASTPASS_SECRETS_PATH="Shared-CF-Oratos/concourse-secrets.yml"
# shellcheck disable=SC2034
LASTPASS_X509_PATH='Shared-Opensource Common/*.ci.cf-app.com SSL key & certs (RSA-2048)'
# shellcheck disable=SC2034
VALUES="
concourse:
  externalURL: https://oratos.ci.cf-app.com
  githubAuth:
    enabled: true
    user: jasonkeene,wfernandes,dennyzhang,chentom88
web:
  service:
    type: NodePort
  ingress:
    annotations:
      kubernetes.io/ingress.allow-http: false
    enabled: true
    hosts:
    - oratos.ci.cf-app.com
    tls:
    - secretName: concourse-web-tls
      hosts:
      - oratos.ci.cf-app.com
"
