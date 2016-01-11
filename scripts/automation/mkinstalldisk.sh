#!/bin/sh

[ -d /mnt/ubuntuiso ] && rm -rf /mnt/ubuntuiso
mkdir -p /mnt/iso
mount -o loop /root/ubuntu-15.10-server-amd64.iso /mnt/iso

mkdir -p /mnt/ubuntuiso
cp -rT /mnt/iso /mnt/ubuntuiso

cd /mnt/ubuntuiso
echo en > isolinux/lang
echo en > isolinux/langlist

#system-config-kickstart
cp /root/ks.cfg .

cp /root/ks.preseed ./preseed/ks.preseed
#cat <<_EOD_ > ks.preseed
#d-i partman/confirm_write_new_label boolean true
#d-i partman/choose_partition select Finish partitioning and write changes to disk
#d-i partman/confirm boolean true
#_EOD_

cp /root/txt.cfg ./install/netboot/ubuntu-installer/amd64/boot-screens/txt.cfg
cp /root/txt.cfg ./isolinux/txt.cfg
cp /root/txt.cfg ./ubuntu/isolinux/txt.cfg

mkisofs -D -r -V "ATTENDLESS_UBUNTU" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o /mnt/autoinstall.iso .
