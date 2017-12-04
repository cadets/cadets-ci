#!/bin/sh

export MAKEOBJDIRPREFIX=${WORKSPACE}/obj
rm -fr ${MAKEOBJDIRPREFIX}

SRCDIR=freebsd
JFLAG=${BUILDER_JFLAG}

cat > ${WORKSPACE}/src.conf <<EOF
WITH_DTRACE_TESTS=yes
EOF

MAKECONF=/dev/null
SRCCONF=${WORKSPACE}/src.conf
TARGET=amd64
TARGET_ARCH=amd64
KERNCONF=CADETS-NODEBUG

cd ${SRCDIR}
nice make -j ${JFLAG} -DNO_CLEAN buildworld \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
nice make -j ${JFLAG} -DNO_CLEAN buildkernel \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        KERNCONF=${KERNCONF} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}
nice make -j ${JFLAG} -DNO_CLEAN packages \
        TARGET=${TARGET} \
        TARGET_ARCH=${TARGET_ARCH} \
        KERNCONF=${KERNCONF} \
        __MAKE_CONF=${MAKECONF} \
        SRCCONF=${SRCCONF}

cd release
nice make clean
nice make -DNO_ROOT -DNOPORTS -DNOSRC -DNODOC packagesystem \
        TARGET=${TARGET} TARGET_ARCH=${TARGET_ARCH} \
        MAKE="make __MAKE_CONF=${MAKECONF} SRCCONF=${SRCCONF} KERNCONF=${KERNCONF}"
