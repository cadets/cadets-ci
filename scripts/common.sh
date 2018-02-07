#
# Ensure that we are exposing every step of the build and that we fail clearly
# if anything goes wrong.
#
set -ex

#
# Use this command to ensure consistent installation of configuration files.
#
export INSTALL="install -o root -g wheel -m 0644"
export INSTALL_RC="install -o root -g wheel -m 0555"

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
		sudo tar xf ${tarball} -C ${DIR}
	done

	# Add firstboot sentinels so that growfs and pkg_bootstrap will run.
	sudo ${INSTALL} /dev/null ufs/firstboot
	sudo ${INSTALL} /dev/null ufs/firstboot-reboot

	# Install our pkg(8) bootstrapping script (which will eventually end up
	# in our FreeBSD distribution)
	sudo ${INSTALL_RC} \
		${CI_ROOT}/configs/default/pkg_bootstrap \
		${DIR}/etc/rc.d/
}
