#!/bin/bash

set -Eeuo pipefail; [ -n "$DEBUG" ] && set -x

source consts.sh
source ../lib.sh
source lib.sh

function main {
    create_cluster
    init_helm
    install_concourse
    poll_loadbalancer_ip
}

main
