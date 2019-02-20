#!/bin/sh

check_envvar()
{
	if ! [ -d "`echo $1`" ]
	then
		>&2 echo "Warning: $1 not set"
	fi
}

#
# Set up build environment, either using variables supplied by Jenkins or
# else expecting a local user running this script to supply them.
#
if [ "${JENKINS_URL}" != "" ]
then
	export JFLAG=${BUILDER_JFLAG:-16}

	# Everything should be stored within the Jenkins job workspace:
	: export ${MAKEOBJDIRPREFIX:=${WORKSPACE}/obj}
	export SRCCONF=${WORKSPACE}/src.conf

	# The CADETS toolchain should have been extracted from various artifact
	# tarballs into known locations:
	export LLVM_PREFIX=${WORKSPACE}/llvm_build
	export LOOM_PREFIX=${WORKSPACE}/loom_build
	export LLVM_PROV_PREFIX=${WORKSPACE}/llvm_prov_build

	SRCDIR=freebsd
else
	export SRCCONF=`mktemp /tmp/src.conf.XXXXXX`

	check_envvar "LLVM_PREFIX"
	check_envvar "LOOM_PREFIX"
	check_envvar "LLVM_PROV_PREFIX"
fi

echo "WITH_DTRACE_TESTS=yes" > ${SRCCONF}


#
# Set other environment variables based on the above configuration
# (which may come from Jenkins or directly from the user):
#

export MAKECONF=/dev/null
export __MAKE_CONF=${MAKECONF}

export TARGET=amd64
export TARGET_ARCH=amd64
export KERNCONF=CADETS

export PATH=${LLVM_PREFIX}:${PATH}

echo "------------------------------------------------------------------------"
echo "Building CADETS with settings:"
echo "------------------------------------------------------------------------"
echo "JFLAG:              ${JFLAG}"
echo "MAKEOBJDIRPREFIX:   ${MAKEOBJDIRPREFIX}"
echo "LLVM_PREFIX:        ${LLVM_PREFIX}"
echo "LOOM_PREFIX:        ${LOOM_PREFIX}"
echo "LLVM_PROV_PREFIX:   ${LLVM_PROV_PREFIX}"
echo "KERNCONF:           ${KERNCONF}"
echo "MAKECONF:           ${MAKECONF}"
echo "PATH:               ${PATH}"
echo "SRCCONF:            ${SRCCONF}"
echo "SRCDIR:             ${SRCDIR}"
echo "TARGET:             ${TARGET}"
echo "TARGET_ARCH:        ${TARGET_ARCH}"
echo "------------------------------------------------------------------------"


#
# Actually build everything:
#

# Clean up old obj tree but don't delete any package repositories.
make -C ${SRCDIR} obj
OBJDIR=`make -C ${SRCDIR} -V .OBJDIR`
find ${OBJDIR} -depth 1 -not -name repo | xargs rm -rf

MAKE=${LLVM_PROV_PREFIX}/scripts/llvm-prov-make


# Disable -Werror in both buildworld (NO_WERROR) and buildkernel (WERROR),
# as we often use a more recent compiler than -CURRENT. Fixing the warnings
# is also a useful activity, but we don't want invalid comparisons in Wi-Fi to
# block forward progress on CADETS.
export NO_WERROR=
export WERROR=

MAKE_FLAGS="-j ${JFLAG} -DNO_CLEAN"

cd ${SRCDIR}
nice ${MAKE} ${MAKE_FLAGS} buildworld
nice ${MAKE} ${MAKE_FLAGS} buildkernel
nice ${MAKE} ${MAKE_FLAGS} -DDB_FROM_SRC packages

#
# Build base.txz and kernel.txz and make them visible by symlinking the default
# directory (deep in the OBJDIR directory hierarchy) to the top level.
#
cd release
${MAKE} ${MAKE_FLAGS} -DNO_ROOT packagesystem
cd ..

cd ..
rm -f release-artifacts
ln -s ${OBJDIR}/release release-artifacts
