#!/bin/bash

set -eu

source consts.sh
source lib.sh

function main {
    upgrade_concourse
}

main
