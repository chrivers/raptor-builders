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

GRUB_LABEL=boot
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
qemu-img create -q -f ${OUTPUT_FORMAT:-raw} ${OUTPUT} ${DISK_SPACE_SIZE_MB}M

Info "Building disk image"
maybe-break buildiso

mkfifo /tmp/pipe
tar -cvf /tmp/pipe -C ${BUILD} . &

export PART_START_EFI=2048
export PART_START_BOOT=$((PART_START_EFI + (DISK_SPACE_EFI_MB * 1024 * 1024) / 512))
export PART_START_ROOT=$((PART_START_BOOT + (DISK_SPACE_BOOT_MB * 1024 * 1024) / 512))

guestfish \
    --no-sync \
    --pipe-error \
    --progress-bars \
    --format=${OUTPUT_FORMAT:-raw} \
    --add /output/disk.img \
    --file /root/disk-image.guestfish

Info "Complete"
