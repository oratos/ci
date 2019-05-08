#!/bin/bash

function create_gcp_service_account {
    gcloud iam service-accounts create $GCP_SERVICE_ACCOUNT
    gcloud iam service-accounts keys create \
        --iam-account='$GCP_SERVICE_ACCOUNT@$GCP_PROJECT.iam.gserviceaccount.com' $GCP_SERVICE_ACCOUNT.key.json
    gcloud projects add-iam-policy-binding cf-pks-observability1 \
        --member='serviceAccount:$GCP_SERVICE_ACCOUNT@$GCP_PROJECT.iam.gserviceaccount.com' --role='roles/editor'

    vault write $VAULT_GCP_VARS_PATH service-account=@$GCP_SERVICE_ACCOUNT.key.json
    rm bosh-concourse.key.json
}

function get_bbl_state {
    rm -rf "$VAULT_BBL_STATE_PATH"
    vault read -format json "$VAULT_BBL_STATE_PATH" \
        | jq --join-output .data.tarball \
        | base64 --decode \
        > bbl-state.tgz
    tar -xzvf bbl-state.tgz 2> /dev/null
    rm bbl-state.tgz
}

function save_bbl_state {
    VAULT_FORMAT="json"

    tar -czf state.tgz bbl-home/
    base64 state.tgz > state.tgz.enc

    vault write $VAULT_BBL_STATE_PATH tarball=@state.tgz.enc
    rm state.tgz state.tgz.enc
}

function bbl_up {
    export BBL_GCP_SERVICE_ACCOUNT_KEY="$(vault read -field=service-account $VAULT_GCP_VARS_PATH)"

    if [ ! -d "bbl" ]
    then
        rm -rf $BBL_STATE_DIR
        mkdir $BBL_STATE_DIR
    fi

    pushd $BBL_STATE_DIR > /dev/null
        bbl up --lb-type concourse
    popd > /dev/null

    save_bbl_state
}

function bbl_down {
    export BBL_GCP_SERVICE_ACCOUNT_KEY="$(vault read -field=service-account $VAULT_GCP_VARS_PATH)"

    pushd $BBL_STATE_DIR > /dev/null
        bbl --no-confirm down
    popd > /dev/null

    vault delete $VAULT_BBL_STATE_PATH
}

function bbl_print_env {
    pushd $BBL_STATE_DIR > /dev/null
       eval "$(bbl print-env)"
    popd > /dev/null
}

function deploy_concourse {
    get_bbl_state
    bbl_print_env

    bosh upload-stemcell https://bosh.io/d/stemcells/bosh-google-kvm-ubuntu-xenial-go_agent

    git clone https://github.com/concourse/concourse-bosh-deployment.git
    trap cleanup_git_repo ERR

    pushd concourse-bosh-deployment/cluster > /dev/null
        vault read -field=concourse_vars.yml $VAULT_CONCOURSE_VARS > concourse_vars.yml
        bosh --deployment concourse deploy --non-interactive concourse.yml \
            --vars-file ../versions.yml \
            --vars-file concourse_vars.yml \
            --ops-file operations/basic-auth.yml \
            --ops-file operations/privileged-https.yml \
            --ops-file operations/tls.yml \
            --ops-file operations/vault.yml \
            --ops-file operations/github-auth.yml \
            --ops-file operations/worker-ephemeral-disk.yml \
            --ops-file ../../worker_instances.yml \
            --ops-file operations/windows-worker.yml \
            --ops-file operations/windows-worker-ephemeral-disk.yml \
            --ops-file ${HOME}/workspace/oratos-ci/provision/concourse/ops-files/windows-tools-2019.yml
    popd > /dev/null

    cleanup_git_repo
}

function cleanup_git_repo {
    rm -rf concourse-bosh-deployment
}

function delete_concourse {
    get_bbl_state
    bbl_print_env

    bosh --deployment concourse delete-deployment --non-interactive --force
}
