#!/bin/sh

#
# Set environment variables that are specific to our Jenkins environment:
#

JFLAG=${BUILDER_JFLAG:-16}
export MAKECONF=/dev/null
export __MAKE_CONF=${MAKECONF}
export SRCCONF=${WORKSPACE}/src.conf
SRCDIR=freebsd
export TARGET=amd64
export TARGET_ARCH=amd64
export KERNCONF=CADETS

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

cd ..
rm -f release-artifacts
ln -s ${OBJDIR}/release release-artifacts
