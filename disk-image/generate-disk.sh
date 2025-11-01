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

GRUB_LABEL=BOOT
BOOT_PATH=/

maybe-break top

compute-disk-space ${LAYERS}
truncate -s${DISK_SPACE_SIZE_MB}M ${OUTPUT}

Info "Building disk image"
maybe-break buildiso

mkfifo /tmp/pipe
tar -cf /tmp/pipe -C ${LAYERS} . &

export PART_START_EFI=2048
export PART_START_BOOT=$((PART_START_EFI + (DISK_SPACE_EFI_MB * 1024 * 1024) / 512))
export PART_START_ROOT=$((PART_START_BOOT + (DISK_SPACE_BOOT_MB * 1024 * 1024) / 512))
guestfish -n --pipe-error --progress-bars -x -n -f /root/disk-image.guestfish

Info "Complete"
