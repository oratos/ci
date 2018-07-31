#!/bin/bash

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

BIKEPARK_BBL_STATE_DIR="${BIKEPARK_BBL_STATE_DIR:-$HOME/workspace/bikepark-bbl-state}"

function bikepark_download-bbl-state {
    mkdir -p "$BIKEPARK_BBL_STATE_DIR"
    pushd "$BIKEPARK_BBL_STATE_DIR" > /dev/null
        vault read -format json secret/envs/bikepark-bbl-state \
            | jq --join-output .data.tarball \
            | base64 --decode \
            > bbl-state.tgz
        tar -xzvf bbl-state.tgz 2> /dev/null
    popd > /dev/null
}

function bikepark_print-env {
    pushd "$BIKEPARK_BBL_STATE_DIR/bbl-state" > /dev/null
        bbl print-env
    popd > /dev/null
}

function bikepark_delete-bbl-state {
    rm -r "$BIKEPARK_BBL_STATE_DIR"
}

function cleanup_bbl_state {
    echo "unable to download bbl-state"
    echo "perhaps you are not logged into vault?"
    echo "removing bbl state"
    rm -r "$BIKEPARK_BBL_STATE_DIR"
    exit 1
}

function bikepark_get-credentials {
    if ! [ -d "$BIKEPARK_BBL_STATE_DIR" ]; then
        echo "downloading state from vault..."
        echo "this may take a while but you only have to do it once"

        trap cleanup_bbl_state ERR
        bikepark_download-bbl-state
        trap '' ERR
    fi
    eval "$(bikepark_print-env)"
    admin_password_key=$(credhub find --name-like /cfcr/kubo-admin-password --output-json | jq --raw-output ".credentials[0].name")
    admin_password=$(credhub get --name "$admin_password_key" --output-json | jq --raw-output .value)

    kubectl config set-cluster bikepark \
      --server="https://bikepark.oratos.ci.cf-app.com" \
      --insecure-skip-tls-verify=true
    kubectl config set-credentials bikepark-admin --token="$admin_password"
    kubectl config set-context bikepark \
      --cluster=bikepark \
      --user=bikepark-admin \
      --namespace=oratos
    kubectl config use-context bikepark
}

function bikepark_get-credentials-tunnel {
    if ! [ -d "$BIKEPARK_BBL_STATE_DIR" ]; then
        echo "downloading state from vault..."
        echo "this may take a while but you only have to do it once"

        trap cleanup_bbl_state ERR
        bikepark_download-bbl-state
        trap '' ERR
    fi
    eval "$(bikepark_print-env)"
    admin_password_key=$(credhub find --name-like /cfcr/kubo-admin-password --output-json | jq --raw-output ".credentials[0].name")
    admin_password=$(credhub get --name "$admin_password_key" --output-json | jq --raw-output .value)

    kubectl config set-cluster bikepark \
      --server="https://localhost:8443" \
      --insecure-skip-tls-verify=true
    kubectl config set-credentials bikepark-admin --token="$admin_password"
    kubectl config set-context bikepark \
      --cluster=bikepark \
      --user=bikepark-admin \
      --namespace=oratos
    kubectl config use-context bikepark

    export BOSH_DEPLOYMENT=cfcr
    master_host=$(
        bosh instances --json \
            | jq '.Tables[].Rows[] | select(.instance | contains("master"))' \
            | jq --slurp --join-output first.ips
    )
    pushd "$BIKEPARK_BBL_STATE_DIR/bbl-state" > /dev/null
        jumpbox_host="$(bbl jumpbox-address)"
        jumpbox_key="$(bbl ssh-key)"
    popd > /dev/null

    agent_out="$(ssh-agent)"
    eval "$agent_out"

    echo "$jumpbox_key" | ssh-add -
    ps aux | grep ssh | grep jumpbox | awk '{print $2}' | while read pid; do
        kill "$pid" || true
    done || true
    mkdir -p ~/.ssh
    ssh-keyscan "$jumpbox_host" >> ~/.ssh/known_hosts 2> /dev/null
    echo "jumpbox_host: $jumpbox_host"
    echo "master_host: $master_host"
    ssh -L "8443:$master_host:8443" "jumpbox@$jumpbox_host" -N -f > /dev/null 2>&1
    kill "$(echo "$agent_out" | grep pid | awk '{print $NF}' | tr ';' ' ')"
}

function print_usage {
    bn="$(basename $0)"
    echo "$bn: [subcommand]"
    echo
    echo -e "\033[1mSubcommands:\033[0m"
    echo "   get-credentials         set kubernetes context"
    echo "   get-credentials-tunnel  set kubernetes context, using a temporary ssh tunnel"
    echo
    echo -e "\033[1mDevelopment Subcommands:\033[0m"
    echo "   print-env           display the bosh/credhub env vars"
    echo "   delete-bbl-state    delete all of the bbl state"
    echo "   download-bbl-state  download bbl state from vault"
}

function parse_argc {
    arg=${1:-}
    case "$arg" in
        -h|-help|--help|help)
            print_usage
            exit 0
            ;;
        print-env|delete-bbl-state|download-bbl-state|get-credentials|get-credentials-tunnel)
            command=bikepark_$arg
            ;;
        *)
            echo -e "Invalid command: $arg\n"
            print_usage
            exit 1
            ;;
    esac
}

function main {
    parse_argc ${1:-}
    shift
    "$command" $@
}

main $@
