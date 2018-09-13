#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/default

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/
sudo ${INSTALL} ${CONFIG}/loader.conf ufs/boot/
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/
sudo ${INSTALL_RC} ${CONFIG}/rc.local ufs/etc/rc.local

build_image disk-test.img ufs raw 2g 200000
