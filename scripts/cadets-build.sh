#!/bin/sh

SRCDIR=freebsd

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
mkdir -p `make -C ${SRCDIR} -V MAKEOBJDIR`

# Find CADETS toolchain:
CADETS=${WORKSPACE}/..
export LLVM_PREFIX=${WORKSPACE}/llvm_build
export LOOM_PREFIX=${WORKSPACE}/loom_build
export LLVM_PROV_PREFIX=${WORKSPACE}/llvm_prov_build

export PATH=${LLVM_PREFIX}:${PATH}

# Clean up old obj tree but don't delete any package repositories.
export JENKINS_OBJ_ROOT=`make -C ${SRCDIR} -V .OBJDIR`
find ${JENKINS_OBJ_ROOT} -depth 1 -not -name repo \
	| xargs rm -rf

JFLAG=${BUILDER_JFLAG:-16}

cat > ${WORKSPACE}/src.conf <<EOF
WITH_DTRACE_TESTS=yes
EOF

MAKE=${LLVM_PROV_PREFIX}/scripts/llvm-prov-make
MAKECONF=/dev/null
SRCCONF=${WORKSPACE}/src.conf
TARGET=amd64
TARGET_ARCH=amd64
KERNCONF=CADETS


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
