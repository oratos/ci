#!/bin/bash

set -eu

# shellcheck disable=SC1091
source consts.sh
# shellcheck disable=SC1091
source lib.sh

function main {
    upgrade_concourse
}

main
