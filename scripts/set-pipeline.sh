#!/bin/bash
set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

function set_globals {
    pipeline="${1:-}"

    DEFAULT_TARGET=oratos

    if [[ ${pipeline} == denver-* ]]; then
        DEFAULT_TARGET=denver
    fi

    TARGET="${TARGET:-${DEFAULT_TARGET}}"
}

function validate_args {
    if [ "$pipeline" = "-h" ] || [ "$pipeline" = "--help" ]; then
        print_usage
        exit 1
    fi
}

function shellcheck_tasks {
    for task in tasks/**/task; do
        pushd .. > /dev/null 2>&1
            shellcheck -x -a oratos-ci/"$task"
        popd > /dev/null 2>&1
    done
}

function shellcheck_pipelines {
    local temp_dir
    local pipeline
    for pipeline in pipelines/*.yml; do
        temp_dir="$(mktemp -d)"
        yq read "$pipeline" --tojson \
            | jq '[.jobs[].plan[] | recurse | select(.config?.run.path == "/bin/bash") | {name: .task, script: .config.run.args[1]}]' \
            | python -c 'import json, sys, os.path
temp_dir = "'"$temp_dir"'"
for s in json.load(sys.stdin):
    path = os.path.join(temp_dir, s["name"]+".sh")
    with open(path, "w") as f:
        f.write(s["script"])'

        if [ -n "$(ls -A "$temp_dir")" ]; then
            pushd .. > /dev/null 2>&1
                shellcheck -x -a "$temp_dir"/*.sh
            popd > /dev/null 2>&1
        fi
    done
}

function set_pipeline {
    echo setting pipeline for "$1"
    fly -t "$TARGET" set-pipeline -p "$1" \
        -l pipelines/vars/global.yml \
        -c <(yq read "pipelines/$1.yml" --tojson)
}

function sync_fly {
    fly -t "$TARGET" sync
}

function set_pipelines {
    if [ "$pipeline" = all ] || [ -z "$pipeline" ]; then
        for pipeline_file in $(find pipelines -depth 1 -iname "*.yml" \
                                | sed 's|^pipelines/||'); do
            set_pipeline "${pipeline_file%.yml}"
        done
        exit 0
    fi

    set_pipeline "$pipeline"
}

function print_usage {
    echo "usage: $0 <pipeline>"
}

function verify_dependencies {
    local failed=false
    local deps=( shellcheck fly yq jq python )

    for d in "${deps[@]}"; do
        if ! command -v "$d" > /dev/null 2>&1; then
            echo "$d required"
            failed=true
        fi
    done

    if [ "$failed" != false ]; then
        exit 1
    fi
}

function main {
    local pipeline="${1:-}"

    verify_dependencies
    set_globals "$pipeline"
    validate_args
    sync_fly
    shellcheck_tasks
    shellcheck_pipelines
    set_pipelines
}
main "$@"
