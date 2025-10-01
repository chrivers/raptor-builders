#!/bin/zsh

set -eu

source ~/common.zsh
source ~/squashfs.zsh
source ~/xorriso.zsh
source ~/grub.zsh
source ~/layerinfo.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/debian-liveboot.iso
BUILD=/output/build
EFIBOOT_IMG=/tmp/efiboot.img

maybe-break top

mkdir -p ${BUILD}/EFI/BOOT
mkdir -p ${BUILD}/boot/grub

Info "Building squashfs layers.."
build-all-squashfs-layers

Info "Generating grub menu"
grub-deblive-menu > ${BUILD}/boot/grub/grub.cfg

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
        [[ -f ${LKERNEL} ]] && {
            KERNEL=$LKERNEL
        }

        local LINITRD=(${INPUT}/boot/initrd.img-*(Nom[1]))
        [[ -f ${LINITRD} ]] && {
            INITRD=$LINITRD
        }
    done

    cp ${KERNEL} ${BUILD}/${DEST}/vmlinuz
    Line "  .. kernel: ${KERNEL}"

    cp ${INITRD} ${BUILD}/${DEST}/initrd
    Line "  .. initrd: ${INITRD}"
done

Info "Building grub image [bios]"
grub-mkstandalone-bios /tmp/bios.img

Info "Building grub image [efi]"
grub-mkstandalone-efi ${BUILD}/EFI/BOOT/bootx64.efi /tmp/efiboot.img

Info "Building iso"
maybe-break buildiso

truncate -s0 ${OUTPUT}

build-dual-bootable-iso /tmp/bios.img /tmp/efiboot.img ${BUILD} ${OUTPUT}

Info "Complete"
