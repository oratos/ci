#!/bin/bash

set -eu

PROJECT_NAME=oratos
CLUSTER_NAME="$PROJECT_NAME-ci"
CLUSTER_ZONE=us-central1-a

function delete_cluster {
    gcloud container clusters delete "$CLUSTER_NAME" --zone "$CLUSTER_ZONE"
}

function delete_k8s_objects {
    kubectl delete all --all --all-namespaces --cascade
}

function main {
    delete_k8s_objects
    delete_cluster
}

main
