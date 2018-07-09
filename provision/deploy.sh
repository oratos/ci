#!/bin/bash

set -eu

# shellcheck disable=SC1091
source consts.sh
# shellcheck disable=SC1091
source lib.sh

function main {
    create_cluster
    init_helm
    install_concourse
    poll_loadbalancer_ip
}

main
