#!/bin/zsh

set -eu

source ~/common.zsh
source ~/squashfs.zsh
source ~/grub.zsh
source ~/bootfiles.zsh
source ~/layerinfo.zsh
source ~/diskspace.zsh

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

compute-disk-space ${BUILD}
truncate -s${DISK_SPACE_SIZE_MB}M ${OUTPUT}

Info "Building disk image"
maybe-break buildiso

mkfifo /tmp/pipe
tar -cvf /tmp/pipe -C ${BUILD} . &
guestfish --progress-bars -x -n -f /root/disk-image.guestfish

Info "Complete"
