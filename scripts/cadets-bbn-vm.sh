#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/bbn
OUTPUT_IMG_NAME=cadets-bbn-vm.qcow2

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

#sudo chroot ufs pip-3.6 install argh avro-json-serializer avro-python3 \
#     confluent-kafka gevent greenlet kazoo netifaces pathtools pip \
#     prometheus-client pykafka PyYAML quickavro requests setuptools \
#     simplejson six tabulate tc-bbn-py watchdog

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/ || exit 1
sudo ${INSTALL} ${CONFIG}/loader.conf ufs/boot/
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/ || exit 1

sudo chroot ufs echo "starc" pw useradd -n darpa -c "DARPA" -s /bin/sh -m -h 0
sudo chroot ufs echo "starc" pw useradd -n bbn -c "BBN" -s /bin/sh -m -h 0

sudo makefs -d 6144 -t ffs -s 200g -o version=2 -Z ufs.img ufs
mkimg -s gpt -f qcow2 \
	-b ufs/boot/pmbr \
	-p freebsd-boot:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
xz -f -0 ${OUTPUT_IMG_NAME}
