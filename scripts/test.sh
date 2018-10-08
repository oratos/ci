#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

function lint_scripts {
    local repo
    repo="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)")"
    shellcheck -x -a $(find "$repo" -iname "*.sh")
}

function main {
    lint_scripts
}

main $@
