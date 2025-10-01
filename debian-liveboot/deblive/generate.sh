#!/bin/zsh

set -eu

source ~/common.zsh
source ~/squashfs.zsh
source ~/grub.zsh
source ~/layerinfo.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/debian-liveboot.iso
BUILD=/output/build
EFIBOOT_IMG=/tmp/efiboot.img

make-layer() {
    local NAME="$1"
    local INPUT="${LAYERS}/$1"
    local DEST="${CACHE}/live"

    local SQUASHFS=${DEST}/${NAME}.squashfs
    if [[ ! $SQUASHFS -nt $INPUT ]]; then
        mksquashfs ${INPUT} ${SQUASHFS} -noappend -comp zstd -quiet -tailends -progress
    fi
    cp ${SQUASHFS} ${BUILD}/live/
}

maybe-break top

mkdir -p ${BUILD}/EFI/BOOT
mkdir -p ${BUILD}/live ${CACHE}/live
mkdir -p ${BUILD}/boot/grub

for layer in $(layerinfo-get-unique-layers); do
    Line "Building layer ${layer}" > /dev/stderr
    make-layer $layer
done

Info "Finished building layers"


grub-deblive-menu-base > ${BUILD}/boot/grub/grub.cfg
for target in $(layerinfo-get-targets); do
    grub-deblive-menu-entry $target "toram" >> ${BUILD}/boot/grub/grub.cfg
done

for target in $(layerinfo-get-targets); do
    Info "Target [${target}]"
    local DEST="boot/${target}"
    mkdir -p ${BUILD}/${DEST}

    truncate -s0 "${BUILD}/live/${target}.module"

    for layer in $(layerinfo-get-layers-for-target $target); do
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
done

Info "Building grub image [bios]"
grub-mkstandalone-bios /tmp/bios.img

Info "Building grub image [efi]"
grub-mkstandalone-efi ${BUILD}/EFI/BOOT/bootx64.efi /tmp/efiboot.img

Info "Building iso"
maybe-break buildiso

truncate -s0 ${OUTPUT}

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -gui \
    -r \
    -full-iso9660-filenames \
    -volid "DEBLIVE" \
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
    /boot/grub/efi.img=/tmp/efiboot.img \
    /boot/grub/bios.img=/tmp/bios.img \
    --output ${OUTPUT} |& (grep -E 'UPDATE' || true)

Info "Complete"
