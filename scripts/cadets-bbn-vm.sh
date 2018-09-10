#!/bin/sh

CI_ROOT=`dirname $0 | xargs dirname`
CONFIG=${CI_ROOT}/configs/bbn

. ${CI_ROOT}/scripts/common.sh

initialize_root_dir ufs base.txz kernel.txz tests.txz

#sudo chroot ufs pip-3.6 install argh avro-json-serializer avro-python3 \
#     confluent-kafka gevent greenlet kazoo netifaces pathtools pip \
#     prometheus-client pykafka PyYAML quickavro requests setuptools \
#     simplejson six tabulate tc-bbn-py watchdog

sudo ${INSTALL} ${CONFIG}/fstab ufs/etc/
sudo ${INSTALL} ${CONFIG}/loader.conf ufs/boot/
sudo ${INSTALL} ${CONFIG}/rc.conf ufs/etc/

sudo chroot ufs echo "starc" pw useradd -n darpa -c "DARPA" -s /bin/sh -m -h 0
sudo chroot ufs echo "starc" pw useradd -n bbn -c "BBN" -s /bin/sh -m -h 0

# bhyve does not currently support qcow2 format, so create "raw" format instead
# build_image cadets-bbn-vm.qcow2 ufs qcow2 200g 1000000
build_image cadets-bbn-vm.img ufs raw 200g 1000000
