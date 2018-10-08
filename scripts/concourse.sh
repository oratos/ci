#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

function concourse_download-bbl-state {
    mkdir -p "$BBL_STATE_DIR"
    pushd "$BBL_STATE_DIR" > /dev/null
        vault read -format json secret/envs/bosh-concourse-bbl-state \
            | jq --join-output .data.tarball \
            | base64 --decode \
            > bbl-state.tgz
        tar -xzvf bbl-state.tgz 2> /dev/null
    popd > /dev/null
}

function concourse_print-env {
    if ! [ -d "$BBL_STATE_DIR" ]; then
        echo "downloading state from vault..."
        echo "this may take a while but you only have to do it once"

        trap cleanup_bbl_state ERR
        concourse_download-bbl-state
        trap '' ERR
    fi

    pushd "$BBL_STATE_DIR/bbl-home" > /dev/null
        bbl print-env
    popd > /dev/null
}

function concourse_delete-bbl-state {
    rm -r "$BBL_STATE_DIR"
}

function cleanup_bbl_state {
    echo "unable to download bbl-state"
    echo "perhaps you are not logged into vault?"
    echo "removing bbl state"
    rm -r "$BBL_STATE_DIR"
    exit 1
}

function print_usage {
    bn="$(basename $0)"
    echo "$bn: <subcommand>"
    echo
    echo -e "\033[1mSubcommands:\033[0m"
    echo "   print-env           display the bosh/credhub env vars"
    echo "   delete-bbl-state    delete all of the bbl state"
    echo "   download-bbl-state  download bbl state from vault"
}

function set_globals {
    BBL_STATE_DIR="${BBL_STATE_DIR:-$HOME/workspace/concourse-bbl-state}"

    local cmd
    cmd=${1:-}
    case "$cmd" in
        print-env|delete-bbl-state|download-bbl-state)
            command=concourse_$cmd
            ;;
        -h|-help|--help|help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "Invalid command: $cmd\n"
            print_usage
            exit 1
            ;;
    esac
}

function main {
    set_globals $@
    shift
    "$command" $@
}

main $@
