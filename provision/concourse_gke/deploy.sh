#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

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
