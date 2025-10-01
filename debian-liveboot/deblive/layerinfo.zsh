function layerinfo-get-unique-layers() {
    local INPUT=${1:-/input/raptor.json}
    jq -r '.layers | flatten | unique | .[]' < $INPUT
}

function layerinfo-get-targets() {
    local INPUT=${1:-/input/raptor.json}
    jq -r '.targets[]' < $INPUT
}

function layerinfo-get-layers-for-target() {
    local TARGET=$1
    local INPUT=${2:-/input/raptor.json}
    jq -r --arg target $TARGET '.layers[$target][]' < $INPUT
}
