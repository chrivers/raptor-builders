build-squashfs-layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/${NAME}"
    local OUTPUT="${CACHE}/live/${NAME}.squashfs"
    local DESTDIR="${BUILD}/live/"

    # Open output file, then take file lock on it
    exec 4<>${OUTPUT}
    flock 4

    # Generate squashfs if:
    #   file is empty (just created by flock)
    #   - or -
    #   input is newer than output
    if [[ ! -s ${OUTPUT} || ${INPUT} -nt ${OUTPUT} ]]; then
        mksquashfs ${INPUT} ${OUTPUT} -noappend -comp zstd -quiet -tailends -progress -xattrs-exclude 'system.posix_acl_.+'
    fi

    flock -u 4

    cp ${OUTPUT} ${DESTDIR}
}

build-all-squashfs-layers() {
    mkdir -p ${BUILD}/live ${CACHE}/live

    for layer in $(layerinfo-get-unique-layers); do
        Line "  .. ${layer}"
        build-squashfs-layer ${layer}
    done
}
