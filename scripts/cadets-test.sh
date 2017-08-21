#!/bin/sh

IMG_NAME=disk-test.img

xz -fd ${IMG_NAME}.xz

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
	-l com1,stdio \
	${TEST_VM_NAME}; \
        expect { eof }"
rc=$?
echo "bhyve return code = $rc"
sudo /usr/sbin/bhyvectl --vm=${TEST_VM_NAME} --destroy

# extract test result
TMP_DIR=`mktemp -d`
MD_UNIT=`sudo mdconfig -a -t vnode -f ${IMG_NAME}`
sudo mount /dev/${MD_UNIT}p3 ${TMP_DIR}

rm -f test-report.*
cp ${TMP_DIR}/usr/tests/test-report.* . || true

sudo umount ${TMP_DIR}
sudo mdconfig -d -u ${MD_UNIT}
rm -fr ${TMP_DIR}
