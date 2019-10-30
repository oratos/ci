# Checkout to shas version used in pks. You can find release version in p-pks-integrations
# use sink-resources release to find the version of the images which should be the same
# as the git shas of the repo
SINK_RESOURCES_REPO=${SINK_RESOURCES_REPO:-~/go/src/github.com/pivotal-cf/sink-resources}
FLUENT_BIT_PLUGIN_REPO=${FLUENT_BIT_PLUGIN_REPO:-~/workspace/fluent-bit-out-syslog}
REMAPPER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/osstp.yaml
OSSTP_LOAD=${OSSTP_LOAD:-~/workspace/osstpclients/bin/osstp-load.py}
OSM_API_KEY_FILE=${OSM_API_KEY_FILE:-~/.osmapikey}

pushd $SINK_RESOURCES_REPO
    osstptool generate --download --remapper-definitions-file=$REMAPPER
    python2 $OSSTP_LOAD -R sink-resources-release/latest osstp_golang.yml -I "Distributed - Static Link w/ TP" -A $OSM_API_KEY_FILE
popd

pushd $FLUENT_BIT_PLUGIN_REPO
    osstptool generate --download --remapper-definitions-file=$REMAPPER
    python2 $OSSTP_LOAD -R sink-resources-release/latest osstp_golang.yml -I "Distributed - Static Link w/ TP" -A $OSM_API_KEY_FILE
popd
