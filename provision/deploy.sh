#!/bin/bash

set -eu

source consts.sh
source lib.sh

function main {
    create_cluster
    init_helm
    install_concourse
    poll_loadbalancer_ip
}

main
