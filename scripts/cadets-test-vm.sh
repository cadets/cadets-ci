#!/bin/sh

OUTPUT_IMG_NAME=disk-test.img

sudo rm -fr ufs > /dev/null 2>&1 || true
sudo chflags -R noschg ufs > /dev/null 2>&1 || true
sudo rm -fr ufs
sudo mkdir ufs
for f in base kernel tests
do
	sudo tar Jxf ${f}.txz -C ufs
done

sudo cp /etc/resolv.conf ufs/etc

# workaround the current tarball has no /etc/passwd can causes pkg fail.
sudo chroot ufs pwd_mkdb -p /etc/master.passwd

sudo chroot ufs env ASSUME_ALWAYS_YES=yes OSVERSION=1200056 pkg update
sudo chroot ufs env OSVERSION=1200056 pkg install -y kyua perl5 pdksh

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/gpt/swapfs none            swap    sw      0       0
/dev/gpt/rootfs /               ufs     rw      1       1
fdesc           /dev/fd         fdescfs rw      0       0
EOF

cat <<EOF | sudo tee ufs/etc/rc.local
#!/bin/sh -ex
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH
echo
echo "--------------------------------------------------------------"
echo "start kyua tests!"
echo "--------------------------------------------------------------"
cd /usr/tests
/usr/local/bin/kyua test
/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt
/usr/local/bin/kyua report-junit --output=test-report.xml
/usr/bin/tar cvf /dev/ada1 test-report.txt test-report.xml
shutdown -p now
EOF

sudo rm -f ufs/etc/resolv.conf

sudo makefs -d 6144 -t ffs -f 200000 -s 2g -o version=2,bsize=32768,fsize=4096 -Z ufs.img ufs
mkimg -s gpt -f raw \
	-b ufs/boot/pmbr \
	-p freebsd-boot/bootfs:=ufs/boot/gptboot \
	-p freebsd-swap/swapfs::1G \
	-p freebsd-ufs/rootfs:=ufs.img \
	-o ${OUTPUT_IMG_NAME}
xz -f -0 ${OUTPUT_IMG_NAME}
