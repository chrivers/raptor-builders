function layerinfo_get_unique_layers() {
    local INPUT=${1:-/input/raptor.json}
    jq -r '.layers | flatten | unique | .[]' < $INPUT
}

function layerinfo_get_targets() {
    local INPUT=${1:-/input/raptor.json}
    jq -r '.targets[]' < $INPUT
}

function layerinfo_get_layers_for_target() {
    local TARGET=$1
    local INPUT=${2:-/input/raptor.json}
    jq -r --arg target $TARGET '.layers[$target][]' < $INPUT
}
