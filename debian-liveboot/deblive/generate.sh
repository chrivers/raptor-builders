#!/bin/zsh

set -eu

source ~/common.zsh
source ~/grub.zsh
source ~/layerinfo.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/iso
BUILD=/output/build
EFIBOOT_IMG=${BUILD}/efiboot.img

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

grub_deblive_menu_base > ${BUILD}/boot/grub/grub.cfg

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

    grub_deblive_menu_entry $target "toram" >> ${BUILD}/boot/grub/grub.cfg
done

cp ${BUILD}/boot/grub/grub.cfg ${BUILD}/EFI/BOOT/grub.cfg

Info "Building grub config"

grub-mkstandalone-bios ${BUILD}/bios.img
grub-mkstandalone-efi ${BUILD}/EFI/BOOT/BOOTX64.EFI

Info "Building efiboot image"

maybe_break efiboot

truncate -s 20M ${EFIBOOT_IMG}
mkfs.vfat ${EFIBOOT_IMG}
mmd -i ${EFIBOOT_IMG} ::/EFI ::/EFI/BOOT
mcopy -vi ${EFIBOOT_IMG} \
      "${BUILD}/EFI/BOOT/BOOTX64.EFI" \
      "${BUILD}/boot/grub/grub.cfg" \
      ::/EFI/BOOT/

Info "Building iso"

cd $BUILD

maybe_break buildiso

cp -r /usr/lib/grub/i386-pc ${BUILD}/boot/grub/i386-pc/

truncate -s0 $OUTPUT/debian-custom.iso

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -quiet \
    -full-iso9660-filenames \
    -volid "DEBLIVE" \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-boot \
    boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
    -eltorito-alt-boot \
    -e ${EFIBOOT_IMG:t} \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -o ${OUTPUT}/debian-custom.iso \
    -graft-points \
    "${BUILD}" \
    /boot/grub/bios.img=${BUILD}/bios.img

Info "Complete"
