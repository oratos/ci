#!/bin/bash

set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

source consts.sh
source ../lib.sh
source lib.sh

function main {
    upgrade_vault
}

main
