#!/bin/bash

set -eEou pipefail

function validate_input {
    type=${1:-}
    version=${2:-}

    if [ -z "$type" ]; then
        echo -e "Type parameter is required \n"
        print_usage
        exit 1
    fi

    if [ -z "$version" ]; then
        echo -e "Version parameter is required \n"
        print_usage
        exit 1
    fi

    case "$type" in
        latency)
            ;;
        crosstalk)
            ;;
        *)
            echo -e "Invalid receiver type: $type \n"
            print_usage
            exit 1
            ;;
    esac

    echo -e "Creating docker image for $type receiver \n"
}

function print_usage {
    bn="$(basename $0)"
    echo "$bn: <type> <version>"
    echo
    echo -e "\033[1mTypes:\033[0m"
    echo "   latency        receiver for the latency tests"
    echo "   crosstalk      receiver for the crosstalk tests"
}

function create_docker {
    type="${1}"
    version="${2}"

    cat "cmd/$type-receiver/Dockerfile" | docker build --tag "oratos/$type-receiver:$version" --file - .
}

function main {
    validate_input $@
    create_docker $@
}

main $@
