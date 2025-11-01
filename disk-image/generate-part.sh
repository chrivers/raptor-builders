#!/bin/zsh

set -eu

source ~/common.zsh
source ~/diskspace.zsh

CACHE=/cache
LAYERS=/input
OUTPUT=/output/disk.img

maybe-break top

compute-part-space ${LAYERS}
truncate -s${DISK_SPACE_SIZE_MB}M ${OUTPUT}

Info "Building disk image"

mkfifo /tmp/pipe
tar -cf /tmp/pipe -C ${LAYERS} . &

maybe-break build

guestfish \
    -x \
    --no-sync \
    --pipe-error \
    --progress-bars \
    --add /output/disk.img \
    --file /root/part-image.guestfish

Info "Complete"
