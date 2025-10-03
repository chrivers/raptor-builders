#!/bin/zsh

set -eu

source ~/common.zsh
source ~/squashfs.zsh
source ~/grub.zsh
source ~/bootfiles.zsh
source ~/layerinfo.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/disk.img
BUILD=/output/build

GRUB_LABEL=BOOT
BOOT_PATH=/

maybe-break top

mkdir -p ${BUILD}/boot/efi/EFI/BOOT
mkdir -p ${BUILD}/boot/grub

Info "Building squashfs layers.."
build-all-squashfs-layers

Info "Generating grub menu"
grub-deblive-menu > ${BUILD}/boot/grub/grub.cfg

Info "Extracting boot files"
extract-boot-files

Info "Building grub image [efi]"
grub-mkstandalone-efi ${BUILD}/boot/efi/EFI/BOOT/bootx64.efi

Info "Computing disk space"
EFI_MB=32
BOOT_MB=512
USED_MB=$(du -sm ${BUILD} | cut -f1 -d$'\t')
FREE_MB=512
SIZE_MB=$((EFI_MB + BOOT_MB + USED_MB + FREE_MB))
Line "  efi:   ${EFI_MB}M"
Line "  boot:  ${BOOT_MB}M"
Line "  used:  ${USED_MB}M"
Line "  free:  ${FREE_MB}M"
Line "  -----"
Line "  total: ${SIZE_MB}M"

truncate -s${SIZE_MB}M ${OUTPUT}

Info "Building disk image"
maybe-break buildiso

mkfifo /tmp/pipe
tar -cvf /tmp/pipe -C ${BUILD} . &
guestfish --progress-bars -x -n -f /root/disk-image.guestfish

Info "Complete"
