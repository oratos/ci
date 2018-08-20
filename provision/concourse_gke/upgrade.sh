#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

source consts.sh
source ../lib.sh
source lib.sh

function main {
    upgrade_concourse
}

main
