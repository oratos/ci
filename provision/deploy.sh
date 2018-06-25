#!/bin/bash

set -eu

PROJECT_NAME=oratos
CLUSTER_NAME="$PROJECT_NAME-ci"
CLUSTER_SIZE=3
CLUSTER_ZONE=us-central1-a
CLUSTER_VERSION=1.10
NAMESPACE_NAME="$CLUSTER_NAME"
LASTPASS_SECRETS_PATH="Shared-CF-Oratos/concourse-secrets.yml"
VALUES="
concourse:
  externalURL: http://oratos.ci.cf-app.com
  githubAuth:
    enabled: true
    user: jasonkeene,wfernandes,dennyzhang
"

function generate_values {
    echo "$VALUES"
    lpass show --notes "$LASTPASS_SECRETS_PATH"
}

function create_cluster {
    echo
    echo
    echo CREATING CLUSTER
    echo

    gcloud container clusters create "$CLUSTER_NAME" \
        --zone="$CLUSTER_ZONE" \
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
        --clusterrole=cluster-admin \
        --serviceaccount=kube-system:tiller
    kubectl patch deploy tiller-deploy \
        --namespace kube-system \
        --patch '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    helm repo update
}

function install_concourse {
    echo
    echo
    echo INSTALLING CONCOURSE
    echo

    # kubectl create namespace "$NAMESPACE_NAME"
    helm install stable/concourse \
        --name concourse \
        --values <(generate_values) \
        --namespace "$NAMESPACE_NAME"
    kubectl expose deployment concourse-web \
        --name concourse-web-public \
        --port 80 \
        --target-port 8080 \
        --type LoadBalancer \
        --namespace "$NAMESPACE_NAME"
}

function loadbalancer_ip {
    kubectl get service concourse-web-public \
        --namespace "$NAMESPACE_NAME" \
        --output=jsonpath='{ .status.loadBalancer.ingress[].ip }'
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
    # create_cluster
    # init_helm
    install_concourse
    poll_loadbalancer_ip
}

main
