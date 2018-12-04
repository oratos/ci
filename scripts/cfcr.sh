#!/bin/bash

set -Eeuo pipefail; [ -n "${DEBUG:-}" ] && set -x

function cfcr_env_download-bbl-state {
    mkdir -p "$BBL_STATE_DIR"
    pushd "$BBL_STATE_DIR" > /dev/null
        vault read -format json "$vault_path" \
            | jq --join-output .data.tarball \
            | base64 --decode \
            > bbl-state.tgz
        tar -xzvf bbl-state.tgz 2> /dev/null
    popd > /dev/null
}

function cfcr_env_print-env {
    if ! [ -d "$BBL_STATE_DIR" ]; then
        echo "downloading state from vault..." >&2
        echo "this may take a while but you only have to do it once" >&2

        trap cleanup_bbl_state ERR
        cfcr_env_download-bbl-state >&2
        trap '' ERR
    fi

    pushd "$BBL_STATE_DIR/bbl-state" > /dev/null
        [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
        bbl print-env
        [ -n "${DEBUG:-}" ] && set -x
    popd > /dev/null
}

function cfcr_env_delete-bbl-state {
    rm -r "$BBL_STATE_DIR"
}

function cleanup_bbl_state {
    echo "unable to download bbl-state"
    echo "perhaps you are not logged into vault?"
    echo "removing bbl state"
    rm -r "$BBL_STATE_DIR"
    exit 1
}

function cfcr_env_get-credentials {
    [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
    eval "$(cfcr_env_print-env)"
    admin_password_key=$(credhub find --name-like /cfcr/kubo-admin-password --output-json | jq --raw-output ".credentials[0].name")
    admin_password=$(credhub get --name "$admin_password_key" --output-json | jq --raw-output .value)
    [ -n "${DEBUG:-}" ] && set -x

    kubectl config set-cluster "$env" \
      --server="https://$domain" \
      --insecure-skip-tls-verify=true
    [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
    kubectl config set-credentials "$env-admin" --token="$admin_password"
    [ -n "${DEBUG:-}" ] && set -x
    kubectl config set-context "$env" \
      --cluster="$env" \
      --user="$env-admin" \
      --namespace=oratos
    kubectl config use-context "$env"
}

function cfcr_env_get-credentials-tunnel {
    [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
    eval "$(cfcr_env_print-env)"
    admin_password_key=$(credhub find --name-like /cfcr/kubo-admin-password --output-json | jq --raw-output ".credentials[0].name")
    admin_password=$(credhub get --name "$admin_password_key" --output-json | jq --raw-output .value)
    [ -n "${DEBUG:-}" ] && set -x

    kubectl config set-cluster "$env" \
      --server="https://localhost:8443" \
      --insecure-skip-tls-verify=true
    [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
    kubectl config set-credentials "$env-admin" --token="$admin_password"
    [ -n "${DEBUG:-}" ] && set -x
    kubectl config set-context "$env" \
      --cluster="$env" \
      --user="$env-admin" \
      --namespace=oratos
    kubectl config use-context "$env"

    export BOSH_DEPLOYMENT=cfcr
    master_host=$(
        bosh instances --json \
            | jq '.Tables[].Rows[] | select(.instance | contains("master"))' \
            | jq --slurp --join-output first.ips
    )
    pushd "$BBL_STATE_DIR/bbl-state" > /dev/null
        jumpbox_host="$(bbl jumpbox-address)"
        [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
        jumpbox_key="$(bbl ssh-key)"
        [ -n "${DEBUG:-}" ] && set -x
    popd > /dev/null

    agent_out="$(ssh-agent)"
    eval "$agent_out"

    [ -n "${DEBUG:-}" ] && set +x # make sure creds are not output
    echo "$jumpbox_key" | ssh-add -
    [ -n "${DEBUG:-}" ] && set -x
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
    echo "$bn: <environment> <subcommand>"
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

function set_globals {
    env=${1:-}
    case "$env" in
        bikepark)
            domain=bikepark.oratos.ci.cf-app.com
            vault_path=secret/envs/bikepark-bbl-state
            ;;
        testing)
            domain=testing-cfcr.oratos.ci.cf-app.com
            vault_path=secret/envs/oratos-ci-testing-cfcr-bbl-state
            ;;
        control-plane-test)
            domain=control-plane-test-cfcr.oratos.ci.cf-app.com
            vault_path=secret/envs/control-plane-test-bbl-state
            ;;
        "")
            print_usage
            exit 0
            ;;
        *)
            echo -e "Invalid environment: $env\n"
            print_usage
            exit 1
            ;;
    esac

    BBL_STATE_DIR="${BBL_STATE_DIR:-$HOME/workspace/$env-bbl-state}"

    local cmd
    cmd=${2:-}
    case "$cmd" in
        print-env|delete-bbl-state|download-bbl-state|get-credentials|get-credentials-tunnel)
            command=cfcr_env_$cmd
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
    shift
    "$command" $@
}

main $@
