#!/bin/bash

set -Eeuo pipefail; [ -n "$DEBUG" ] && set -x

source consts.sh
source ../lib.sh
source lib.sh

function main {
    delete_k8s_objects
    delete_cluster
}

main
