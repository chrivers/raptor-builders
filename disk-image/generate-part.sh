#!/bin/zsh

set -eu

source ~/common.zsh
source ~/diskspace.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/disk.img

maybe-break top

compute-part-space ${LAYERS}
qemu-img create -q -f ${OUTPUT_FORMAT:-raw} ${OUTPUT} ${DISK_SPACE_SIZE_MB}M

Info "Building disk image"

mkfifo /tmp/pipe
tar -cf /tmp/pipe -C ${LAYERS} . &

maybe-break build

guestfish \
    --no-sync \
    --pipe-error \
    --progress-bars \
    --format=${OUTPUT_FORMAT:-raw} \
    --add /output/disk.img \
    --file /root/part-image.guestfish

Info "Complete"
