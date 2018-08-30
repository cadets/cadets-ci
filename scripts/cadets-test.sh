#!/bin/sh

IMG_NAME=disk-test.img
TAR_FILE=results.tar
TAR_FILE_SIZE=128m

EXECUTOR_NUMBER=${EXECUTOR_NUMBER:-0}
TAP_IF=tap${EXECUTOR_NUMBER}
BRIDGE_IF=bridge0

xz -fd ${IMG_NAME}.xz

# assume the physical interface of the host is the first in the ifconfig list
PHY_IF=$(ifconfig -l|cut -d " " -f1,1)

#load the bhyve module if not loaded
sudo kldload -n vmm
    
# prepare the host
#   cleanup
sudo ifconfig ${TAP_IF} destroy || true
#   prepare network interface
sudo ifconfig ${TAP_IF} create
sudo sysctl net.link.tap.up_on_open=1
if [ `ifconfig ${BRIDGE_IF} 2> /dev/null | wc -l` -eq 0 ]; then
	sudo ifconfig ${BRIDGE_IF} create
	sudo ifconfig ${BRIDGE_IF} addm ${PHY_IF}
	sudo ifconfig ${BRIDGE_IF} up
fi
sudo ifconfig ${BRIDGE_IF} addm ${TAP_IF}

rm -f ${TAR_FILE}
truncate -s ${TAR_FILE_SIZE} ${TAR_FILE}

# run test VM image with bhyve
TEST_VM_NAME=${JOB_NAME}-${BUILD_NUMBER}
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 8192m -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout 14340; \
	spawn sudo /usr/bin/timeout -k 60 14280 /usr/sbin/bhyve \
	-c 2 -m 8192m -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	-s 3:0,ahci-hd,${TAR_FILE} \
	-s 4:0,virtio-net,${TAP_IF} \
	-l com1,stdio \
	${TEST_VM_NAME}; \
	expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract test result
rm -f test-report.*
tar xvf ${TAR_FILE}

#remove the changed made to the host
sudo ifconfig ${BRIDGE_IF} deletem ${TAP_IF}
sudo ifconfig ${TAP_IF} destroy


if [ `ifconfig ${BRIDGE_IF} | grep member: | grep -v $PHY_IF` -eq 0 ]; then
	sudo ifconfig ${BRIDGE_IF} destroy
fi
