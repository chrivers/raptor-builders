#!/bin/sh

# Portable service image would normally be a file, but the easiest way to get it
# available in the vm, is to mount it as another disk. Since we are booting from
# an iso, this will be sda.
cat /dev/sda > /tmp/test.raw
portablectl attach /tmp/test.raw

# Delete systemd sandbox override, to allow service to communicate with serial
# port on /dev/ttyS0
rm /etc/systemd/system.attached/test.service.d/10-profile.conf

# Reload after removing sandbox override
systemctl daemon-reload

# Start portable service
systemctl start test

# Portable service can't power off from inside the chroot, so do it here
poweroff
