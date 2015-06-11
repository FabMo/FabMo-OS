#!/bin/sh

# Update the system
pacman --noconfirm -Syu
pacman --noconfirm -S base-devel git

# Install liveroot by bluerider (enables a root overlay)
git clone https://github.com/bluerider/liveroot /tmp/liveroot
cp /tmp/liveroot/initcpio/hooks/* /usr/lib/initcpio/hooks
cp /tmp/liveroot/initcpio/install/* /usr/lib/initcpio/install

# Configure and install an initial ramdisk environment
# with root overlay enabled.
echo 'MODULES="overlay"
FILES=""
BINARIES=""
HOOKS="base udev oroot autodetect modconf block filesystems keyboard fsck"
COMPRESSION="gzip"
COMPRESSION_OPTIONS=""' > /tmp/mkinitcpio.conf
mkinitcpio -c /tmp/mkinitcpio.conf -g /boot/initramfs-linux.img

# Configure bootloader settings to enable root overlay with kernel params
mkdir -p /mnt/boot
mount /dev/mmcblk1p1 /mnt/boot
echo 'optargs=coherent_pool=1M oroot=raw' > /mnt/boot/uEnv.txt

# Install dependencies for fabmo
pacman --noconfirm -S python2 nodejs npm

# Install fabmo
rm -rf /fabmo /opt/fabmo
mkdir /fabmo
mkdir -p /opt/fabmo
git clone https://github.com/FabMo/FabMo-Engine.git /fabmo
cd /fabmo
npm install

# Configure fabmo as a service
echo '[Unit]
Description=FabMo Engine

[Service]
ExecStart=/bin/node /fabmo/server.js &
Type=simple
User=root
Restart=always
StandardOutput=syslog
StandardError=syslog
WorkingDirectory=/fabmo/

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/fabmo.service

systemctl enable fabmo

