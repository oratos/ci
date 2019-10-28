SINK_RESOURCES_REPO=${SINK_RESOURCES_REPO:-~/go/src/github.com/pivotal-cf/sink-resources}
FLUENT_BIT_PLUGIN_REPO=${FLUENT_BIT_PLUGIN_REPO:-~/workspace/fluent-bit-out-syslog}
REMAPPER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/osstp.yaml
pushd $SINK_RESOURCES_REPO
osstptool generate --download --remapper-definitions-file=$REMAPPER

popd
pushd $FLUENT_BIT_PLUGIN_REPO
osstptool generate --download --remapper-definitions-file=$REMAPPER

popd
