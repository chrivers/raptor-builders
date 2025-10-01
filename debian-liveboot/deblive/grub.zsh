grub_deblive_menu_base() {
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

grub_deblive_menu_entry() {
    local TARGET=$1
    local ARGS=$2
    local DEST=${DEST:-"boot/${target}"}
    local LABEL=${LABEL:-"DEBLIVE"}

    cat <<EOF
menuentry "Debian Live [${TARGET}]" {
    search --no-floppy --set=root --label ${LABEL}
    linux (\$root)/${DEST}/vmlinuz boot=live toram module=${TARGET}
    initrd (\$root)/${DEST}/initrd
}
EOF
}

grub-redirect-config() {
    local LABEL=${1:-"DEBLIVE"}

    cat <<EOF
search --no-floppy --set=root --label ${LABEL}
source (\$root)/boot/grub/grub.cfg
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
    local IMG_TARGET=$2

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

    truncate -s 20M ${IMG_TARGET}
    mkfs.vfat ${IMG_TARGET}
    mmd -i ${IMG_TARGET} ::/EFI ::/EFI/BOOT
    mcopy -vi ${IMG_TARGET} ${EFI_TARGET} ::/EFI/BOOT/bootx64.efi
}
