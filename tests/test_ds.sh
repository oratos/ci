#!/bin/bash -ex
##-------------------------------------------------------------------
##
## File : test_ds.sh
## Author : Denny, Warren
## Description :
## --
## Created : <2017-08-15>
## Updated: Time-stamp: <2018-06-25 11:51:36>
##-------------------------------------------------------------------
function setup_daemonset() {
    echo "Setup Daemonset"
    kubectl apply -f configmap/fluent-bit-configmap.yml
    kubectl apply -f daemonsets/daemonset.yaml
}

function verify_daemonset() {
    echo "Verify Daemonset deployment"
    kubectl get daemonsets -n oratos | grep fluent-bit
    kubectl get pods -n oratos | grep fluent-bit.*Running
}

cd ..

setup_daemonset
verify_daemonset
## File : test_ds.sh ends
