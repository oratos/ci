#!/bin/bash -e
##-------------------------------------------------------------------
##
## File : test_ds.sh
## Author : Denny, Warren
## Description :
## --
## Created : <2017-08-15>
## Updated: Time-stamp: <2018-06-25 11:30:47>
##-------------------------------------------------------------------
function setup_daemonset() {
    echo "Setup Daemonset"
}

function verify_daemonset() {
    echo "Verify Daemonset deployment"
    kubectl get daemonsets -n oratos
    kubectl get pods -n oratos
}

kubectl get daemonsets --namespace oratos
## File : test_ds.sh ends
