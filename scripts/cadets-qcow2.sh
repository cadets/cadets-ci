#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/qcow2
OUTPUT_IMG_NAME=disk-vm.qcow2

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/
sudo ${INSTALL} ${CONFIG}/loader.conf ufs/boot/

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s gpt -f qcow2 \
	-b ufs/boot/pmbr \
	-p freebsd-boot:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
xz -f -0 ${OUTPUT_IMG_NAME}
