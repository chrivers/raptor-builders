build-squashfs-layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/${NAME}"
    local OUTPUT="${CACHE}/live/${NAME}.squashfs"
    local DESTDIR="${BUILD}/live/"

    exec 4<>$OUTPUT.lock
    flock 4

    if [[ ! $OUTPUT -nt $INPUT ]]; then
        mksquashfs ${INPUT} ${OUTPUT} -noappend -comp zstd -quiet -tailends -progress
    fi

    flock -u 4

    cp ${OUTPUT} ${DESTDIR}
}

build-all-squashfs-layers() {
    mkdir -p ${BUILD}/live ${CACHE}/live

    for layer in $(layerinfo-get-unique-layers); do
        Line "  .. ${layer}"
        build-squashfs-layer $layer
    done
}
