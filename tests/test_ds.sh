#!/bin/bash -ex
##-------------------------------------------------------------------
##
## File : test_ds.sh
## Author : Denny <zdenny@vmware.com>, Warren <wfernandes@pivotal.io>
## Description :
## --
## Created : <2017-08-15>
## Updated: Time-stamp: <2018-06-25 12:03:24>
##-------------------------------------------------------------------
function setup_daemonset() {
    echo "Setup Daemonset"
    kubectl apply -f namespace/namespace.yml
    kubectl apply -f configmap/fluent-bit-configmap.yml
    kubectl apply -f daemonsets/daemonset.yaml
}

function verify_daemonset() {
    echo "Verify Daemonset deployment"
    # TODO: more test logic
    kubectl get daemonsets -n oratos | grep fluent-bit
    # TODO: verify the running instance count should be 2
    kubectl get pods -n oratos | grep fluent-bit.*Running
}

cd ..

setup_daemonset
verify_daemonset
## File : test_ds.sh ends
