#!/bin/zsh

set -eu

source ~/common.zsh
source ~/diskspace.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/disk.img

maybe-break top

compute-disk-space ${LAYERS}
qemu-img create -q -f ${OUTPUT_FORMAT:-raw} ${OUTPUT} ${DISK_SPACE_SIZE_MB}M

Info "Building disk image"

mkfifo /tmp/pipe
tar -cf /tmp/pipe -C ${LAYERS} . &

export PART_START_EFI=2048
export PART_START_BOOT=$((PART_START_EFI + (DISK_SPACE_EFI_MB * 1024 * 1024) / 512))
export PART_START_ROOT=$((PART_START_BOOT + (DISK_SPACE_BOOT_MB * 1024 * 1024) / 512))

maybe-break build

guestfish \
    --no-sync \
    --pipe-error \
    --progress-bars \
    --format=${OUTPUT_FORMAT:-raw} \
    --add /output/disk.img \
    --file /root/disk-image.guestfish

Info "Complete"
