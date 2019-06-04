#!/bin/bash -eu

echo "bosh-targeting denver concourse; you may have to hit enter to continue"
pushd ~/workspace/denver-deployments/concourse
    eval "$(./target-director.sh)"
popd

credhub set -n /concourse/oratos/github-private-key \
    -t value \
    --value "$(vault kv get --field=oratos-bot-private-key secret/concourse/main/github)"

credhub set -n /concourse/oratos/toolsmiths-api-token \
    -t value \
    --value "$(vault kv get --field=apitoken secret/concourse/main/toolsmiths)"
