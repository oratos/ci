#!/bin/bash

# This script is used to update the image version of the observability-manager
# in the p-pks-integrations plan selectors.

set -Eeo pipefail; [ -n "$DEBUG" ] && set -x; set -u

function usage {
    echo "usage: $0 <observability-manager-version>

example:
    $0 v0.1" >&2
}


VERSION=${1:-}

if [ -z "$VERSION" ] ; then
    usage
    exit 1
fi

if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.?[0-9]*$ ]]; then
    echo version needs to be in the form v1.4.1
    exit 1
fi

for f in $(find "$HOME/workspace/p-pks-integrations/properties/" -iname "plan*selector*"); do
    sed -i '' "s|oratos/observability-manager:v[[:digit:]]*.[[:digit:]]*.[[:digit:]]*|oratos/observability-manager:$VERSION|g" $f
done
