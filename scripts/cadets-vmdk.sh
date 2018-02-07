#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/default

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/fstab
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/

build_image disk-vm.vmdk ufs vmdk 2g 200000
