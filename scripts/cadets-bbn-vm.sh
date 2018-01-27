#!/bin/sh

OUTPUT_IMG_NAME=cadets-bbn-vm.qcow2

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
sudo chroot ufs env OSVERSION=1200056 pkg install -y sudo bash alpine autoconf automake avro-cpp \
     bison cmake coreutils curl git gmake htop jansson jq jsoncpp kafkacat \
     librdkafka libtool links m4 maven33 nginx ninja openjdk8 php56 postfix \
     postgresql95-client postgresql95-server postgresql95-contrib tmux vim \
     emacs25 wget zsh python3 py36-setuptools py36-pip

#sudo chroot ufs pip-3.6 install argh avro-json-serializer avro-python3 \
#     confluent-kafka gevent greenlet kazoo netifaces pathtools pip \
#     prometheus-client pykafka PyYAML quickavro requests setuptools \
#     simplejson six tabulate tc-bbn-py watchdog

cat <<EOF | sudo tee ufs/etc/fstab
# Device        Mountpoint      FStype  Options Dump    Pass#
/dev/vtbd0p3	/               ufs     rw      1       1
fdesc           /dev/fd         fdescfs rw      0       0
EOF

cat <<EOF | sudo tee ufs/boot/loader.conf
virtio_console_load="YES"
EOF

cat <<EOF | sudo tee ufs/etc/rc.conf
hostname="cadets-bbn"
ifconfig_vtnet0="DHCP"
sshd_enable="YES"
ntpd_enable="YES"
auditd_enable=“YES”
EOF

sudo rm -f ufs/etc/resolv.conf

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
