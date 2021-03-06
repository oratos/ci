#!/bin/bash
set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

function set_globals {
    pipeline="${1:-}"
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
            shellcheck -e SC2164 -x -a oratos-ci/"$task"
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
                shellcheck -e SC2164  -x -a "$temp_dir"/*.sh
            popd > /dev/null 2>&1
        fi
    done
}

function set_pipeline {
    echo setting pipeline for "$1"
    local vars_file
    if [[ $1 == *"0.19.x"* ]]; then
        vars_file="pipelines/vars/v0.19.x.yml"
    else
        vars_file="pipelines/vars/master.yml"
    fi
    credentials_file=$(mktemp)
    gcs_creds_file=$(mktemp)
    osm_creds_file=$(mktemp)

    pipeline_file="pipelines/${1}.yml"
    erb_file="${pipeline_file}.erb"
    if [[ -f "${erb_file}" ]]; then
      erb ${erb_file} > /dev/null #this way if the erb fails the script bails
      pipeline_file=$(mktemp)
      erb ${erb_file} > ${pipeline_file}
    fi
    vault read -field=vars_file /secret/concourse/vcna/variables > $credentials_file
    vault read -field=vars_file /secret/concourse/main/gcs > $gcs_creds_file
    vault read -field=vars_file /secret/concourse/main/osm > $osm_creds_file
    fly -t oratos-vmw set-pipeline -p "$1" \
        -l "${vars_file}" \
        -l "${credentials_file}" \
        -l "${gcs_creds_file}" \
        -l "${osm_creds_file}" \
        -c "${pipeline_file}"
}

function sync_fly {
    fly -t oratos-vmw sync
}

function set_pipelines {
    if [ "$pipeline" = all ] || [ -z "$pipeline" ]; then
        for pipeline_file in $(ls -1 pipelines | grep '\.yml$' | sed -e 's/\.yml$//'); do
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
