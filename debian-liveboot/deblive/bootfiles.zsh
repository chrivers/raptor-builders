function extract-boot-files() {
    for target in $(layerinfo-get-targets); do
        Info "Target [${target}]"
        local DEST="boot/${target}"
        mkdir -p ${BUILD}/${DEST}

        truncate -s0 "${BUILD}/live/${target}.module"

        local KERNEL=
        local INITRD=

        for layer in $(layerinfo-get-layers-for-target $target); do
            echo "${layer}.squashfs" >> "${BUILD}/live/${target}.module"

            local INPUT="${LAYERS}/${layer}"

            local LKERNEL=(${INPUT}/boot/vmlinuz-*(Nom[1]))
            [[ -f ${LKERNEL} ]] && { KERNEL=$LKERNEL }

            local LINITRD=(${INPUT}/boot/initrd.img-*(Nom[1]))
            [[ -f ${LINITRD} ]] && { INITRD=$LINITRD }
        done

        cp ${KERNEL} ${BUILD}/${DEST}/vmlinuz
        Line "  .. kernel: ${KERNEL}"

        cp ${INITRD} ${BUILD}/${DEST}/initrd
        Line "  .. initrd: ${INITRD}"
    done
}
