#!/bin/bash
set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

function set_globals {
    pipeline="${1:-}"
    TARGET="${TARGET:-oratos}"
}

function validate {
    if [ "$pipeline" = "-h" ] || [ "$pipeline" = "--help" ]; then
        print_usage
        exit 1
    fi
}

function set_pipeline {
    echo setting pipeline for "$1"
    fly -t "$TARGET" set-pipeline -p "$1" -c <(
        cat "pipelines/$1.yml" \
            | yq read - --tojson \
            | jq '.jobs[].build_logs_to_retain = 20'
    )
}

function sync_fly {
    fly -t "$TARGET" sync
}

function set_pipelines {
    if [ "$pipeline" = all ] || [ -z "$pipeline" ]; then
        for pipeline_file in $(ls "pipelines/"); do
            set_pipeline "${pipeline_file%.yml}"
        done
        exit 0
    fi

    set_pipeline "$pipeline"
}

function print_usage {
    echo "usage: $0 <pipeline>"
}

function main {
    local pipeline="${1:-}"

    set_globals "$pipeline"
    validate
    sync_fly
    set_pipelines
}
main $@
