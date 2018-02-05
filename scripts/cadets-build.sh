#!/bin/sh

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj

# Find CADETS toolchain:
CADETS=${WORKSPACE}/..
export LLVM_PREFIX=${CADETS}/LLVM-cadets/BUILD_TYPE/Release/Release
export LOOM_PREFIX=${CADETS}/Loom/BUILD_TYPE/Release/build
LLVM_PROV_TOP=${CADETS}/llvm-prov
export LLVM_PROV_PREFIX=${LLVM_PROV_TOP}/BUILD_TYPE/Release/build

export PATH=${LLVM_PREFIX}:${PATH}

# Clean up old obj tree but don't delete any package repositories.
export JENKINS_OBJ_ROOT=`make -C ${SRCDIR} -V .OBJDIR`
find ${JENKINS_OBJ_ROOT} -depth 1 -not -name repo \
	| xargs rm -rf

SRCDIR=freebsd
JFLAG=${BUILDER_JFLAG}

cat > ${WORKSPACE}/src.conf <<EOF
WITH_DTRACE_TESTS=yes
EOF

MAKE=${LLVM_PROV_TOP}/src/scripts/llvm-prov-make
MAKECONF=/dev/null
SRCCONF=${WORKSPACE}/src.conf
TARGET=amd64
TARGET_ARCH=amd64
KERNCONF=CADETS-NODEBUG

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
nice ${MAKE} -j ${JFLAG} -DNO_CLEAN packages \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        KERNCONF=${KERNCONF} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}

cd release
nice ${MAKE} clean
nice ${MAKE} -DNO_ROOT -DNOPORTS -DNOSRC -DNODOC packagesystem \
        TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
        MAKE="${MAKE} __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF} KERNCONF=${KERNCONF}"

cd ..
RELEASE_DIR="./obj`pwd`/${TARGET}.${TARGET_ARCH}/release"
cd ..
rm -rf release-artifacts
ln -s ${RELEASE_DIR} release-artifacts
