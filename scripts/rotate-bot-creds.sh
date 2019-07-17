#!/bin/bash -eu

set -o pipefail

function print_usage() {
    cat >&2 <<USAGE
Usage: $0

This script will rotate the access token, SSH keys and password of a GitHub user
and store the new credentials in your credential manager.

NOTE: ALL existing personal access tokens and SSH keys will be deleted.

It assumes that your bot username and password are stored in LastPass.

Required environment variables:
    BOT_LPASS_ACCOUNT: Path in LastPass to your bot's GitHub username/password.
    CRED_MANAGER:      'vault' or 'credhub'. Set the *_VAULT_* or *_CREDHUB_*
                       environment variables accordingly.
    SHARED_VAULT_PATH: Path to the Vault secret containing your bot's GitHub key
                       and access token.
    TOKEN_VAULT_FIELD: Field of the above secret containing your bot's GitHub
                       personal access token.
    KEY_VAULT_FIELD:   Field of the above secret containing your bot's GitHub SSH
                       private key.
    TOKEN_NOTE:        Note attached to your bot's GitHub personal access token.
    KEY_NOTE:          Note attached to your bot's GitHub SSH key.

Optional environment variables:
    KEY_TYPE:          One of 'ed25519' (default), 'rsa', 'dsa' or 'ecdsa'.
USAGE
}

function require_env() {
    declare -a missing
    for env in "$@"; do
        if [[ -z "${!env}" ]]; then
            missing[${#missing[@]}]=$env
        fi
    done

    if [[ -n "${missing:-}" ]]; then
        echo "Error: missing environment variable(s):" $(printf ", %s" "${missing}" | cut -b 3-) >&2
        echo
        print_usage
        exit 1
    fi
}

function check_config() {
    if [[ ${CRED_MANAGER:-} != vault && ${CRED_MANAGER:-} != credhub ]]; then
        print_usage
        exit 1
    fi

    require_env BOT_LPASS_ACCOUNT TOKEN_NOTE

    case $CRED_MANAGER in
        vault)
            require_env SHARED_VAULT_PATH TOKEN_VAULT_FIELD KEY_VAULT_FIELD

            if ! vault list /secret > /dev/null; then
                echo "Please log in to vault."
                exit 1
            fi
            ;;

        credhub)
            echo "FIXME: credhub support not yet implemented"
            exit 1
            ;;
    esac
}

function fetch_bot_creds_from_lpass() {
    if [[ -z "${BOT_LPASS_ACCOUNT:-}" ]]; then
        print_usage
        exit 1
    fi

    if ! lpass ls > /dev/null; then
        echo "Please log in to lastpass."
        exit 1
    fi

    GITHUB_USERNAME="$(lpass show "$BOT_LPASS_ACCOUNT" --username)"
    GITHUB_PASSWORD="$(lpass show "$BOT_LPASS_ACCOUNT" --password)"
}

function github_curl() {
    local path="$1"; shift

    curl -sL --fail --show-error -u "$GITHUB_USERNAME:$GITHUB_PASSWORD" https://api.github.com${path#https://api.github.com} "$@"
}

function vault_patch() {
    local key=$1
    local field=$2
    local value=$3

    (vault kv get -format=json $key || echo '{}') | jq --argjson value "$value" '.data | ."'$field'" = $value' | vault kv put $key -
}

function set_personal_access_token() {
    case $CRED_MANAGER in
        vault)
            vault_patch $SHARED_VAULT_PATH $TOKEN_VAULT_FIELD "\"$1\""
            ;;
    esac
}

function set_ssh_key() {
    case $CRED_MANAGER in
        vault)
            vault_patch $SHARED_VAULT_PATH $KEY_VAULT_FIELD "$1"
            ;;
    esac
}

function rotate_personal_access_token() {
    local PERSONAL_ACCESS_TOKEN_CLIENT_ID="00000000000000000000"

    local personal_access_token_urls
    personal_access_token_urls="$(github_curl /authorizations | jq -r 'map(select(.app.client_id=="00000000000000000000")) | .[].url')"

    if [[ -z "$personal_access_token_urls" ]]; then
        echo "No existing personal access tokens found"
    else
        for token_url in "$personal_access_token_urls"; do
            github_curl "$token_url" -X DELETE
        done
    fi

    local create_token_body='{"scopes":["repo"],"note":"'"$TOKEN_NOTE"'","client_id":"'"$PERSONAL_ACCESS_TOKEN_CLIENT_ID"'"}'
    local new_personal_access_token
    new_personal_access_token="$(github_curl /authorizations -d "$create_token_body" | jq -r .token)"

    set_personal_access_token "$new_personal_access_token"
}

function rotate_ssh_key() {
    local ssh_key_urls
    ssh_key_urls="$(github_curl /user/keys | jq -r '.[].url')"

    if [[ -z "$ssh_key_urls" ]]; then
        echo "No existing SSH keys found"
    else
        for key_url in "$ssh_key_urls"; do
            github_curl "$key_url" -X DELETE
        done
    fi

    local key_dir="$(mktemp -d)"
    trap "rm -r $key_dir" EXIT

    ssh-keygen -t ${KEY_TYPE:-ed25519} -N '' -f ${key_dir}/key

    local create_key_body='{"title":"'"$KEY_NOTE"'", "key":"'"$(cat ${key_dir}/key.pub)"'"}'

    github_curl /user/keys -d "$create_key_body"

    set_ssh_key "$(cat ${key_dir}/key | jq --slurp --raw-input .)"
}

check_config
fetch_bot_creds_from_lpass

rotate_personal_access_token
rotate_ssh_key
