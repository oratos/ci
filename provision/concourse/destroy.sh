#!/bin/bash

set -eu

source consts.sh
source lib.sh

function main {
    delete_k8s_objects
    delete_cluster
}

main
