#!/bin/zsh

set -eu

source ~/common.zsh
source ~/layerinfo.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/iso
BUILD=/output/build
EFIBOOT_IMG=${BUILD}/efiboot.img
ISOLINUX=${BUILD}/isolinux

make_layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/$1"
    local DEST="${CACHE}/live"

    local SQUASHFS=${DEST}/${NAME}.squashfs
    if [[ ! $SQUASHFS -nt $INPUT ]]; then
        mksquashfs ${INPUT} ${SQUASHFS} -noappend -comp zstd -quiet -tailends -progress
    fi
    cp ${SQUASHFS} ${BUILD}/live/
}

maybe_break top

mkdir -p ${BUILD}/EFI/BOOT
mkdir -p ${BUILD}/live ${CACHE}/live
mkdir -p ${BUILD}/boot/grub
mkdir -p ${ISOLINUX}

cp /root/grub.cfg ${BUILD}/boot/grub/

cp ${BUILD}/boot/grub/grub.cfg ${BUILD}/EFI/BOOT/grub.cfg

for layer in $(layerinfo_get_unique_layers); do
    Line "Building layer ${layer}" > /dev/stderr
    make_layer $layer
done

Info "Finished building layers"

for target in $(layerinfo_get_targets); do
    Info "Target [${target}]"
    local DEST="boot/${target}"
    mkdir -p ${BUILD}/${DEST}
    truncate -s0 "${BUILD}/live/${target}.module"

    echo -n > "${BUILD}/${DEST}/${target}.module"
    for layer in $(layerinfo_get_layers_for_target $target); do
        echo "${layer}.squashfs" >> "${BUILD}/live/${target}.module"

        local INPUT="${LAYERS}/${layer}"

        local KERNEL=(${INPUT}/boot/vmlinuz-*(Nom[1]))
        [[ -f ${KERNEL} ]] && {
            cp ${KERNEL} ${BUILD}/${DEST}/vmlinuz
            Line "Found kernel: ${KERNEL}"
        }

        local INITRD=(${INPUT}/boot/initrd.img-*(Nom[1]))
        [[ -f ${INITRD} ]] && {
            cp ${INITRD} ${BUILD}/${DEST}/initrd
            Line "Found initrd: ${INITRD}"
        }
    done

    cat <<EOF >> ${BUILD}/EFI/BOOT/grub.cfg
menuentry "Debian Live [${target}]" {
    search --no-floppy --set=root --label DEBLIVE
    linux (\$root)/${DEST}/vmlinuz boot=live toram module=${target}
    initrd (\$root)/${DEST}/initrd
}
EOF
done

Info "Building grub config"

grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos fat iso9660 ext2" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="${BUILD}/EFI/BOOT/BOOTX64.EFI"
#     "boot/grub/grub.cfg=${OUTPUT}/tmp/grub-embed.cfg"

cd $BUILD

Info "Building efiboot image"

maybe_break efiboot

truncate -s 20M ${EFIBOOT_IMG}
mkfs.vfat ${EFIBOOT_IMG}
mmd -i ${EFIBOOT_IMG} ::/EFI ::/EFI/BOOT
mcopy -vi ${EFIBOOT_IMG} \
      "EFI/BOOT/BOOTX64.EFI" \
      "boot/grub/grub.cfg" \
      ::/EFI/BOOT/

Info "Building iso"

maybe_break buildiso

cp \
    /usr/lib/ISOLINUX/isolinux.bin \
    /usr/lib/ISOLINUX/isohdpfx.bin \
    /usr/lib/syslinux/modules/bios/* \
    ${ISOLINUX}

truncate -s0 $OUTPUT/debian-custom.iso

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -quiet \
    -full-iso9660-filenames \
    -volid "DEBLIVE" \
    -joliet -joliet-long -rational-rock \
    -isohybrid-mbr isolinux/isohdpfx.bin \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -boot-load-size 4 \
    -boot-info-table \
    -no-emul-boot \
    -eltorito-alt-boot \
    -e ${EFIBOOT_IMG:t} \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o ${OUTPUT}/debian-custom.iso \
    ${BUILD}

Info "Complete"
