build-squashfs-layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/${NAME}"
    local OUTPUT="${CACHE}/live/${NAME}.squashfs"
    local DESTDIR="${BUILD}/live/"

    if [[ ! $OUTPUT -nt $INPUT ]]; then
        mksquashfs ${INPUT} ${OUTPUT} -noappend -comp zstd -quiet -tailends -progress
    fi
    cp ${OUTPUT} ${DESTDIR}
}

build-all-squashfs-layers() {
    mkdir -p ${BUILD}/live ${CACHE}/live

    for layer in $(layerinfo-get-unique-layers); do
        Line "  .. ${layer}"
        build-squashfs-layer $layer
    done
}
