#!/bin/bash

set -eu

PROJECT_NAME=oratos
CLUSTER_NAME="$PROJECT_NAME-ci"
CLUSTER_SIZE=3
CLUSTER_ZONE=us-central1-a
CLUSTER_VERSION=1.10
NAMESPACE_NAME="$CLUSTER_NAME"
LASTPASS_SECRETS_PATH="Shared-CF-Oratos/concourse-secrets.yml"
LASTPASS_X509_PATH='Shared-Opensource Common/*.ci.cf-app.com SSL key & certs (RSA-2048)'
VALUES="
concourse:
  externalURL: https://oratos.ci.cf-app.com
  githubAuth:
    enabled: true
    user: jasonkeene,wfernandes,dennyzhang
web:
  service:
    type: NodePort
  ingress:
    annotations:
      kubernetes.io/ingress.allow-http: \"false\"
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

function create_cluster {
    echo
    echo
    echo CREATING CLUSTER
    echo

    gcloud container clusters create "$CLUSTER_NAME" \
        --zone "$CLUSTER_ZONE" \
        --cluster-version "$CLUSTER_VERSION" \
        --num-nodes "$CLUSTER_SIZE"
}

function init_helm {
    echo
    echo
    echo INITIALIZING HELM
    echo

    helm init --wait
    kubectl create serviceaccount tiller \
        --namespace kube-system
    kubectl create clusterrolebinding tiller-cluster-rule \
        --clusterrole cluster-admin \
        --serviceaccount kube-system:tiller
    kubectl patch deploy tiller-deploy \
        --patch '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' \
        --namespace kube-system
    helm repo update

    echo waiting for tiller to be ready
    while [ "$(tiller_ready)" != "true" ]; do
        echo -n .
        sleep 2
    done
}

function tiller_ready {
    kubectl get pods \
        --selector name=tiller \
        --output jsonpath='{ .items[0].status.containerStatuses[0].ready }' \
        --namespace kube-system
}

function cert {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN CERTIFICATE-----$/,/-----END CERTIFICATE-----/p"
}

function key {
    lpass show "$LASTPASS_X509_PATH" | \
        sed -n "/^-----BEGIN PRIVATE KEY-----$/,/-----END PRIVATE KEY-----/p"
}

function install_concourse {
    echo
    echo
    echo INSTALLING CONCOURSE
    echo

    cert_file="$(mktemp)"
    key_file="$(mktemp)"
    cert > "$cert_file"
    key > "$key_file"

    kubectl create namespace "$NAMESPACE_NAME"
    kubectl create secret tls concourse-web-tls \
        --cert "$cert_file" \
        --key "$key_file" \
        --namespace "$NAMESPACE_NAME"
    helm install stable/concourse \
        --name concourse \
        --values <(generate_values) \
        --namespace "$NAMESPACE_NAME"

    rm "$cert_file"
    rm "$key_file"
}

function loadbalancer_ip {
    kubectl get ingress concourse-web \
        --output jsonpath='{ .status.loadBalancer.ingress[0].ip }' \
        --namespace "$NAMESPACE_NAME"
}

function poll_loadbalancer_ip {
    echo
    echo
    echo POLLING FOR LOAD BALANCER
    echo

    local lb_ip
    while true; do
        lb_ip="$(loadbalancer_ip)"
        if [ "$lb_ip" != "" ]; then
            break
        fi
        echo -n .
        sleep 2
    done

    echo
    echo "Load Balancer IP: $lb_ip"
    echo
    echo Configure the DNS for your External URL to point to this IP.
    echo
}

function main {
    create_cluster
    init_helm
    install_concourse
    poll_loadbalancer_ip
}

main
