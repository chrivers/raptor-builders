build-dual-bootable-iso() {
    local IMG_BIOS=$1
    local IMG_EFI=$2
    local BUILD=$3
    local OUTPUT=$4

    local LABEL=${LABEL:-"DEBLIVE"}

    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -gui \
        -r \
        -full-iso9660-filenames \
        -volid ${LABEL} \
        -joliet -joliet-long \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        --boot-catalog-hide \
        \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        \
        --efi-boot boot/grub/efi.img \
        -efi-boot-part --efi-boot-image \
        \
        -graft-points \
        /=${BUILD} \
        /boot/grub/efi.img=${IMG_EFI} \
        /boot/grub/bios.img=${IMG_BIOS} \
        --output ${OUTPUT} |& (grep -E 'UPDATE' || true)
}
