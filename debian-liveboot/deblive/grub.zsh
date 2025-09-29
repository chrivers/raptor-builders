grub_deblive_menu_entry() {
    local TARGET=$1
    local ARGS=$2
    local DEST=${DEST:-"boot/${target}"}

    cat <<EOF
menuentry "Debian Live [${TARGET}]" {
    search --no-floppy --set=root --label DEBLIVE
    linux (\$root)/${DEST}/vmlinuz boot=live toram module=${TARGET}
    initrd (\$root)/${DEST}/initrd
}
EOF
}
