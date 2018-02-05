#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/default
OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr ufs > /dev/null 2>&1 || true
sudo chflags -R noschg ufs > /dev/null 2>&1 || true
sudo rm -fr ufs
sudo mkdir ufs
for f in base kernel tests
do
	sudo tar Jxf ${f}.txz -C ufs
done

# workaround the current tarball has no /etc/passwd can causes pkg fail.
sudo chroot ufs pwd_mkdb -p /etc/master.passwd

sudo env ASSUME_ALWAYS_YES=yes OSVERSION=1200056 pkg -c ufs update
sudo env OSVERSION=1200056 pkg -c ufs install -y kyua perl5 pdksh

sudo cp ${CONFIG}/fstab ufs/etc/ || exit 1
sudo cp ${CONFIG}/run-tests.rc ufs/etc/rc.local || exit 1

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s gpt -f raw \
	-b ufs/boot/pmbr \
	-p freebsd-boot/bootfs:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
xz -f -0 ${OUTPUT_IMG_NAME}
