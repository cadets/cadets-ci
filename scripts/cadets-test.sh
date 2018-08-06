#!/bin/sh

IMG_NAME=disk-test.img
TAR_FILE=results.tar
TAR_FILE_SIZE=128m

xz -fd ${IMG_NAME}.xz

# assume the physical interface of the host is the first in the ifconfig list
PHY_IF=$(ifconfig -l|cut -d " " -f1,1)

#load the bhyve module if not loaded
sudo kldstat|grep -q vmm 
if [ $? -ne 0 ]
then
    sudo kldload vmm
fi
    
# prepare the host
sudo ifconfig tap0 create
sudo sysctl net.link.tap.up_on_open=1
sudo ifconfig bridge0 create
sudo ifconfig bridge0 addm ${PHY_IF} addm tap0
sudo ifconfig bridge0 up


rm -f ${TAR_FILE}
truncate -s ${TAR_FILE_SIZE} ${TAR_FILE}

# run test VM image with bhyve
TEST_VM_NAME=${JOB_NAME}-${BUILD_NUMBER}
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy || true
sudo /usr/sbin/bhyveload -c stdio -m 4096m -d ${IMG_NAME} ${TEST_VM_NAME}
set +e
expect -c "set timeout 7140; \
	spawn sudo /usr/bin/timeout -k 60 7020 /usr/sbin/bhyve \
	-c 2 -m 4096m -A -H -P -g 0 \
	-s 0:0,hostbridge \
	-s 1:0,lpc \
	-s 2:0,ahci-hd,${IMG_NAME} \
	-s 3:0,ahci-hd,${TAR_FILE} \
	-s 4:0,virtio-net,tap0 \
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
sudo ifconfig tap0 destroy
sudo ifconfig bridge0 destroy
