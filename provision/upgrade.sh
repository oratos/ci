
#!/bin/bash

set -eu

LASTPASS_SECRETS_PATH="Shared-CF-Oratos/concourse-secrets.yml"
VALUES="
concourse:
  externalURL: https://oratos.ci.cf-app.com
  githubAuth:
    enabled: true
    user: jasonkeene,wfernandes,DennyZhang
web:
  service:
    type: NodePort
  ingress:
    annotations:
      kubernetes.io/ingress.allow-http: "false"
    enabled: true
    hosts:
    - oratos.ci.cf-app.com
    tls:
    - secretName: concourse-web-tls
      hosts:
      - oratos.ci.cf-app.com
"

function generate_values {
    echo "$VALUES"
    secrets
}

function secrets {
    lpass show --notes "$LASTPASS_SECRETS_PATH"
}

function upgrade_concourse {
    echo
    echo
    echo UPGRADING CONCOURSE
    echo
    helm upgrade concourse stable/concourse --values <(generate_values)
}

function main {
    upgrade_concourse
}

main
