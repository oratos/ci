#!/bin/bash

set -eu

# shellcheck disable=SC1091
source consts.sh
# shellcheck disable=SC1091
source lib.sh

function main {
    delete_k8s_objects
    delete_cluster
}

main
