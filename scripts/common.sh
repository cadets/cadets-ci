#
# Use this command to ensure consistent installation of configuration files.
#
export INSTALL="install -o root -g wheel -m 0644"
export INSTALL_RC="install -o root -g wheel -m 0644"

#
# Initialize a named directory with a set of specified tarballs, deleting
# the directory if it already exists.
#
# Usage:  `initialize_root_dir dirname base.txz kernel.txz tests.txz`
#
initialize_root_dir()
{
	DIR="$1"
	shift
	TARBALLS="$*"

	if [ -e ${DIR} ]
	then
		sudo rm -rf ${DIR} > /dev/null 2>&1 || true
		sudo chflags -R noschg ${DIR} > /dev/null 2>&1 || true
		sudo rm -rf ${DIR}
	fi

	sudo mkdir -p ${DIR}

	for tarball in ${TARBALLS}
	do
		sudo tar xf ${tarball} -C ${DIR} || exit 1
	done
}

#
# Install a set of named packages in the given chroot directory,
# bootstrapping pkg(8) along the way.
#
# Usage:  `bootstrap_packages dirname sudo vim git`
#
bootstrap_packages()
{
	packages="$*"

	# A missing /etc/passwd can cause pkg(8) to fail.
	sudo chroot ${DIR} pwd_mkdb -p /etc/master.passwd || exit 1

	# Temporarily copy the host's /etc/resolv.conf
	sudo cp /etc/resolv.conf ${DIR}/etc || exit 1

	# Install pkg(8) itself.
	sudo env ASSUME_ALWAYS_YES=yes OSVERSION=1200056 \
		pkg -c ${DIR} update \
		|| exit 1

	# Install the requested packages.
	sudo env OSVERSION=1200056 pkg -c ${DIR} install -y ${packages} \
		|| exit 1

	# Remove temporary /etc/resolv.conf
	sudo rm ${DIR}/etc/resolv.conf
}
