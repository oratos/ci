#!/bin/bash

set -eu

source consts.sh
source ../lib.sh
source lib.sh

function main {
    create_cluster
    init_helm
    install_vault
    poll_loadbalancer_ip
}

main
