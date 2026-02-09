#!/bin/sh

log() {
    printf "\033[34;1m<\033[32;1m*\033[34;1m>\033[0m %s\n" "$*"
}

line() {
    printf "\033[34;1m<\033[;1m|\033[34;1m>\033[0m %s\n" "$*"
}

set -exu

log "Installing grub"

GRUB_MODULES="cat boot chain configfile normal part_gpt part_msdos fat ext2 linux efi_gop efi_uga all_video test gfxterm font cbls loadenv gzio echo minicmd search"

for mod in bli efifwsetup blscfg increment linuxefi; do
    if [ -e /usr/lib/grub/x86_64-efi/${mod}.mod ] || [ -e /usr/lib/grub2/x86_64-efi/${mod}.mod ]; then
        line "  ..add module ${mod}"
        GRUB_MODULES="$GRUB_MODULES $mod"
    fi
done

if [ -x /usr/sbin/grub2-install ]; then
    line '  ..grub2-mkimage'
    mkdir -p /boot/efi/EFI/BOOT
    grub2-mkimage --prefix '(hd0,2)/grub2' -O x86_64-efi -o /boot/efi/EFI/BOOT/BOOTX64.EFI ${GRUB_MODULES}
elif [ -x /usr/sbin/grub-install ]; then
    line '  ..grub-mkimage'
    mkdir -p /boot/efi/EFI/BOOT /boot/grub
    grub-mkimage --prefix '(hd0,2)/grub' -O x86_64-efi -o /boot/efi/EFI/BOOT/BOOTX64.EFI ${GRUB_MODULES}
else
    log 'Cannot find grub-install'
    exit 1
fi

if [ -x /usr/sbin/grub2-mkconfig ]; then
    log 'Running grub2-mkconfig..'
    grub2-mkconfig -o /boot/grub2/grub.cfg
elif [ -x /usr/sbin/grub-mkconfig ]; then
    log 'Running grub-mkconfig..'
    grub-mkconfig -o /boot/grub/grub.cfg
else
    log 'Cannot find grub-mkconfig'
    exit 1
fi
