build-squashfs-layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/${NAME}"
    local OUTPUT="${CACHE}/live/${NAME}.squashfs"
    local HASHED="${OUTPUT:h}/${NAME##*-}.squashfs"
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

        # Link to hashed name, i.e:
        #
        #   675DE2C3A4D8CD82.squashfs -> index.docker.io-library-debian-trixie-675DE2C3A4D8CD82.squashfs
        #
        # Without this shortname, the overlayfs can easily fail to mount,
        # since the combined paths parameter grows too large.
        #
        # To improve this, we use these shortened (but unique) symlinked layers.
        # There is still a limit on the number of layers that can be stacked,
        # but with constant-length names, this is at least a predictable number
        # of layerrs, instead on depending on the layer names.
        ln -sf ${OUTPUT:t} ${HASHED}
    fi

    flock -u 4

    cp -a ${OUTPUT} ${HASHED} ${DESTDIR}
}

build-all-squashfs-layers() {
    mkdir -p ${BUILD}/live ${CACHE}/live

    for layer in $(layerinfo-get-unique-layers); do
        Line "  .. ${layer}"
        build-squashfs-layer ${layer}
    done
}
