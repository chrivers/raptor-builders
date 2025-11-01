function compute-disk-space() {
    local TARGET=$1

    Info "Computing disk space"

    local EFI_MB=${EFI_MB:-32}
    local BOOT_MB=${BOOT_MB:-512}
    local USED_MB=${USED_MB:-$(du -sm ${TARGET} | cut -f1 -d$'\t')}
    local FREE_MB=${FREE_MB:-512}
    local SIZE_MB=${SIZE_MB:-$((EFI_MB + BOOT_MB + USED_MB + FREE_MB))}

    Line "  efi:   ${EFI_MB}M"
    Line "  boot:  ${BOOT_MB}M"
    Line "  used:  ${USED_MB}M"
    Line "  free:  ${FREE_MB}M"
    Line "  -----"
    Line "  total: ${SIZE_MB}M"

    echo ${SIZE_MB}
}
