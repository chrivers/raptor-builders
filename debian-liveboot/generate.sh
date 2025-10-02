#!/bin/zsh

set -eu

source ~/common.zsh
source ~/squashfs.zsh
source ~/xorriso.zsh
source ~/grub.zsh
source ~/bootfiles.zsh
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

Info "Extracting boot files"
extract-boot-files

Info "Building grub image [bios]"
grub-mkstandalone-bios /tmp/bios.img

Info "Building grub image [efi]"
grub-mkstandalone-efi ${BUILD}/EFI/BOOT/bootx64.efi /tmp/efiboot.img

Info "Building iso"
maybe-break buildiso

build-dual-bootable-iso /tmp/bios.img /tmp/efiboot.img ${BUILD} ${OUTPUT}

Info "Complete"
