#!/bin/sh

#
# Set environment variables that are specific to our Jenkins environment:
#

JFLAG=${BUILDER_JFLAG:-16}
MAKECONF=/dev/null
SRCCONF=${WORKSPACE}/src.conf
SRCDIR=freebsd
TARGET=amd64
TARGET_ARCH=amd64
KERNCONF=CADETS

cat > ${SRCCONF} <<EOF
WITH_DTRACE_TESTS=yes
EOF

# CADETS toolchain:
export LLVM_PREFIX=${WORKSPACE}/llvm_build
export LOOM_PREFIX=${WORKSPACE}/loom_build
export LLVM_PROV_PREFIX=${WORKSPACE}/llvm_prov_build

export PATH=${LLVM_PREFIX}:${PATH}

#
# Actually build everything:
#

# Clean up old obj tree but don't delete any package repositories.
make -C ${SRCDIR} obj
find `make -C ${SRCDIR} -V .OBJDIR` \
	-depth 1 \
	-not -name repo \
	| xargs rm -rf

MAKE=${LLVM_PROV_PREFIX}/scripts/llvm-prov-make


# Disable -Werror in both buildworld (NO_WERROR) and buildkernel (WERROR),
# as we often use a more recent compiler than -CURRENT. Fixing the warnings
# is also a useful activity, but we don't want invalid comparisons in Wi-Fi to
# block forward progress on CADETS.
export NO_WERROR=
export WERROR=

cd ${SRCDIR}
nice ${MAKE} -j ${JFLAG} -DNO_CLEAN buildworld \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
nice ${MAKE} -j ${JFLAG} -DNO_CLEAN buildkernel \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        KERNCONF=${KERNCONF} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
nice ${MAKE} -j ${JFLAG} -DNO_CLEAN -DDB_FROM_SRC packages \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        KERNCONF=${KERNCONF} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}

RELEASE_DIR="./obj`pwd`/${TARGET}.${TARGET_ARCH}/release"
cd ..
rm -rf release-artifacts
ln -s ${RELEASE_DIR} release-artifacts
