function compute-disk-space() {
    local TARGET=$1

    Info "Computing disk space"

    DISK_SPACE_EFI_MB=${EFI_MB:-32}
    DISK_SPACE_BOOT_MB=${BOOT_MB:-512}
    DISK_SPACE_FREE_MB=${FREE_MB:-512}
    DISK_SPACE_USED_MB=${USED_MB:-$(du -sm ${TARGET} | cut -f1 -d$'\t')}
    DISK_SPACE_SIZE_MB=${SIZE_MB:-$((DISK_SPACE_EFI_MB + DISK_SPACE_BOOT_MB + DISK_SPACE_USED_MB + DISK_SPACE_FREE_MB))}

    Line "  efi:   ${DISK_SPACE_EFI_MB}M"
    Line "  boot:  ${DISK_SPACE_BOOT_MB}M"
    Line "  used:  ${DISK_SPACE_USED_MB}M"
    Line "  free:  ${DISK_SPACE_FREE_MB}M"
    Line "  -----"
    Line "  total: ${DISK_SPACE_SIZE_MB}M"
}
