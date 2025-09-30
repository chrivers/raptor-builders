cat <<EOF > ${BUILD}/isolinux/isolinux.cfg
path
prompt 0
timeout 0
include menu.cfg
default vesamenu.c32
EOF

cat <<EOF > ${BUILD}/isolinux/menu.cfg
menu background splash.png
menu color title        * #FFFFFFFF *
menu color border       * #00000000 #00000000 none
menu color sel          * #ffffffff #76a1d0ff *
menu color hotsel       1;7;37;40 #ffffffff #76a1d0ff *
menu color tabmsg       * #ffffffff #00000000 *
menu color help         37;40 #ffdddd00 #00000000 none

# XXX When adjusting vshift, take care that rows is set to a small
# enough value so any possible menu will fit on the screen,
# rather than falling off the bottom.
menu vshift 8
menu rows 12

# The help line must be at least one line from the bottom.
menu helpmsgrow 14

# The command line must be at least one line from the help line.
menu cmdlinerow 16
menu timeoutrow 16
menu tabmsgrow 18
menu tabmsg Press ENTER to boot or TAB to edit a menu entry

menu hshift 4
menu width 70

# menu title Debian GNU/Linux installer menu (BIOS mode)
EOF

    cat <<EOF >> ${BUILD}/isolinux/menu.cfg
label $target
    menu label Debian Live [${target}]
    kernel /${DEST}/vmlinuz
    append vga=788 initrd=/${DEST}/initrd boot=live toram module=${target}
EOF
