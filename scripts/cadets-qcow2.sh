#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/qcow2

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/
sudo ${INSTALL} ${CONFIG}/loader.conf ufs/boot/

build_image disk-vm.qcow2 ufs qcow2 2g 200000
