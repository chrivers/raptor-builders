grub-deblive-menu-base() {
    cat <<EOF
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660

insmod all_video
insmod font

set default="0"
set timeout=5

EOF
}

grub-deblive-menu-entry() {
    local TARGET=$1
    shift
    local ARGS=$*

    local BOOT_PATH=${BOOT_PATH:-"/boot"}
    local GRUB_PATH=${GRUB_PATH:-"${BOOT_PATH}/grub"}
    local GRUB_LABEL=${GRUB_LABEL:-"DEBLIVE"}
    local TARGET_PATH=${TARGET_PATH:-"${BOOT_PATH}/${target}"}

    cat <<EOF
menuentry "Debian Live [${TARGET}]" {
    search --no-floppy --set=root --label ${GRUB_LABEL}
    linux (\$root)/${TARGET_PATH}/vmlinuz boot=live module=${TARGET} ${ARGS}
    initrd (\$root)/${TARGET_PATH}/initrd
}
EOF
}

grub-deblive-menu() {
    grub-deblive-menu-base
    for target in $(layerinfo-get-targets); do
        grub-deblive-menu-entry $target "toram"
    done
}

grub-redirect-config() {
    local GRUB_LABEL=${GRUB_LABEL:-"DEBLIVE"}
    local BOOT_PATH=${BOOT_PATH:-"/boot"}
    local GRUB_PATH=${GRUB_PATH:-"${BOOT_PATH}/grub"}

    cat <<EOF
search --no-floppy --set=root --label ${GRUB_LABEL}
source (\$root)${GRUB_PATH}/grub.cfg
EOF
}

grub-mkstandalone-bios() {
    local TARGET=$1

    local DEFAULT_MODULES=(
        linux
        normal
        iso9660
        fat
        ext2
        cat
        configfile
        biosdisk
        search
        memdisk
        tar
        ls
        part_gpt
        part_msdos
        all_video
        font
        minicmd
        ${GRUB_EXTRA_MODULES:-}
    )

    grub-redirect-config > /tmp/grub.cfg

    grub-mkstandalone \
        --format=i386-pc \
        --install-modules="${GRUB_MODULES:-$DEFAULT_MODULES}" \
        --modules="${GRUB_MODULES:-$DEFAULT_MODULES}" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=/tmp/grub.cfg" \
        --output=/tmp/grub-core.img

    cat \
        /usr/lib/grub/i386-pc/cdboot.img \
        /tmp/grub-core.img \
        > ${TARGET}
}

grub-mkstandalone-efi() {
    local EFI_TARGET=$1
    local IMG_TARGET=${2:-}

    local DEFAULT_MODULES=(
        part_gpt
        part_msdos
        fat
        iso9660
        ext2
        ${GRUB_EXTRA_MODULES:-}
    )

    grub-redirect-config > /tmp/grub.cfg

    grub-mkstandalone \
        -O x86_64-efi \
        --modules="${GRUB_MODULES:-$DEFAULT_MODULES}" \
        --locales="" \
        --themes="" \
        --fonts="" \
        "boot/grub/grub.cfg=/tmp/grub.cfg" \
        --output=$EFI_TARGET

    if [[ -n $IMG_TARGET ]]; then
        truncate -s 20M ${IMG_TARGET}
        mformat -i ${IMG_TARGET}
        mmd -i ${IMG_TARGET} ::/EFI ::/EFI/BOOT
        mcopy -i ${IMG_TARGET} ${EFI_TARGET} ::/EFI/BOOT/bootx64.efi
    fi
}
