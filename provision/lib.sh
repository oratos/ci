
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

function delete_cluster {
    gcloud container clusters delete "$CLUSTER_NAME" --zone "$CLUSTER_ZONE"
}

function delete_k8s_objects {
    for namespace in $(kubectl get ns --output jsonpath="{.items[*].metadata.name}" \
        | sed "s/kube-system//g")
    do
        kubectl -n $namespace delete all --all --cascade
    done
}

function init_helm {
    echo
    echo
    echo INITIALIZING HELM
    echo

    kubectl create serviceaccount tiller \
        --namespace kube-system
    kubectl create clusterrolebinding tiller-cluster-rule \
        --clusterrole cluster-admin \
        --serviceaccount kube-system:tiller
    helm init --service-account tiller

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
