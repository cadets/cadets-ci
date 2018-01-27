#!/usr/bin/env sh

set -e

echo "Installing needed packages..."
su root -c 'env OSVERSION=1200056 pkg install sudo python3 git maven3 gmake'

#echo "Installing optional packages..."
# sudo pkg install vim
# sudo pkg install bash
# sudo pkg install tmux

echo "Installing pip..."
sudo python3 -m ensurepip
sudo pip3 install requests watchdog requests prometheus_client netifaces

echo "Installing librdkafka"
# sudo pkg install librdkafka
# not sure why just installing the package doesn't work.
# manually install it from the source instead
ls -d librdkafka-0.9.2-RC1 > /dev/null 2>&1 || curl -L https://github.com/edenhill/librdkafka/archive/v0.9.2-RC1.tar.gz | tar xzf -
cd librdkafka-0.9.2-RC1/
./configure --prefix=/usr
gmake
sudo gmake install
cd ..

echo "Cloning BBNs repos..."
ls -d ta3-serialization-schema > /dev/null 2>&1 || git clone https://git.tc.bbn.com/bbn/ta3-serialization-schema.git
cd ta3-serialization-schema
mvn clean exec:java
mvn install
cd ..

ls -d ta3-api-bindings-python > /dev/null 2>&1 || git clone https://git.tc.bbn.com/bbn/ta3-api-bindings-python.git
cd ta3-api-bindings-python
sudo python3 setup.py install
cd ..

echo "Cloning CADETS repos..."
ls -d ta1-integration-cadets > /dev/null 2>&1 || git clone https://github.com/cadets/ta1-integration-cadets.git
# no installation steps required

ls -d dtrace-scripts > /dev/null 2>&1 || git clone https://github.com/cadets/dtrace-scripts.git
# no installation steps required

ls -d freebsd > /dev/null 2>&1 || git clone https://github.com/cadets/freebsd.git

echo "Building CADETS..."
cd freebsd
sudo make -j12 buildworld buildkernel > log
sudo make installworld installkernel
sudo cp freebsd/contrib/openbsm/etc/audit_event /etc/security/audit_event

echo "Reboot to start running the new kernel"
#sudo reboot
