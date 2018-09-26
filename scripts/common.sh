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

	# Create initial /etc/passwd using *host* pwd_mkdb(8).
	sudo pwd_mkdb -d ufs/etc ufs/etc/master.passwd

	# Add firstboot sentinels so that growfs and pkg_bootstrap will run.
	sudo ${INSTALL} /dev/null ufs/firstboot
	sudo ${INSTALL} /dev/null ufs/firstboot-reboot

	# Install our pkg(8) bootstrapping script (which will eventually end up
	# in our FreeBSD distribution)
	sudo ${INSTALL_RC} \
	     ${CI_ROOT}/configs/default/pkg_bootstrap \
	     ${CI_ROOT}/configs/default/cadets_pkg_bootstrap \
		${DIR}/etc/rc.d/
}


#
# Build a VM image from a [ch]root directory.
#
# Usage:  build_image <image_name> <root_directory> <image_type>
#                     <root_fs_size> [root_fs_min_inodes]
#
build_image()
{
	image_name=$1
	directory=$2
	image_type=$3
	ufs_size=$4
	ufs_inodes=$5

	makefs_flags="-t ffs -s ${ufs_size} -Z" # FFS on a sparse file
	makefs_flags="${makefs_flags} -d 6144"  # undoc. debug flags (!)
	makefs_flags="${makefs_flags} -o version=2,bsize=32768,fsize=4096"

	if [ -n "${ufs_inodes}" ]
	then
		makefs_flags="${makefs_flags} -f ${ufs_inodes}"
	fi

	sudo makefs ${makefs_flags} -f 200000  -Z rootfs.img ${directory}

	mkimg -s gpt -f ${image_type} \
		-b ufs/boot/pmbr \
		-p freebsd-boot/bootfs:=ufs/boot/gptboot \
		-p freebsd-swap/swapfs::1G \
		-p freebsd-ufs/rootfs:=rootfs.img \
		-o ${image_name}

	xz -f -0 ${image_name}
}
