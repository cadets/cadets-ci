#!/bin/sh

OUTPUT_IMG_NAME=disk-vm.qcow2

sudo rm -fr ufs > /dev/null 2>&1 || true
sudo chflags -R noschg ufs > /dev/null 2>&1 || true
sudo rm -fr ufs
sudo mkdir ufs
for f in base kernel tests
do
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc

# workaround the current tarball has no /etc/passwd can causes pkg fail.
sudo chroot ufs pwd_mkdb -p /etc/master.passwd

sudo chroot ufs env ASSUME_ALWAYS_YES=yes pkg update
sudo chroot ufs pkg install -y kyua perl5 pdksh

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/vtbd0s1a	/               ufs     rw      1       1
fdesc           /dev/fd         fdescfs rw      0       0
EOF

cat <<EOF | sudo tee ufs/boot/loader.conf
console="comconsole"
comconsole_speed="115200"
virtio_console_load="YES"
EOF

sudo rm -f ufs/etc/resolv.conf

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s bsd \
	-b ufs/boot/boot \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o /tmp/bsd.img
mkimg -s mbr -f qcow2 \
	-b ufs/boot/mbr \
	-p freebsd:=bsd.img \
	-o ${OUTPUT_IMG_NAME}
xz -f -0 ${OUTPUT_IMG_NAME}
