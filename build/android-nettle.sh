#!/bin/bash

if [[ -z ${ANDROID_NDK_ROOT} ]]; then
    echo "ANDROID_NDK_ROOT not defined"
    exit 1
fi

if [[ -z ${ARCH} ]]; then
    echo "ARCH not defined"
    exit 1
fi

if [[ -z ${API} ]]; then
    echo "API not defined"
    exit 1
fi

if [[ -z ${BASEDIR} ]]; then
    echo "BASEDIR not defined"
    exit 1
fi

# ENABLE COMMON FUNCTIONS
. ${BASEDIR}/build/android-common.sh

# PREPARING PATHS & DEFINING ${INSTALL_PKG_CONFIG_DIR}
LIB_NAME="nettle"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
TARGET_HOST=$(get_target_host)
export CFLAGS=$(get_cflags ${LIB_NAME})
export CXXFLAGS=$(get_cxxflags ${LIB_NAME})
export LDFLAGS=$(get_ldflags ${LIB_NAME})
export PKG_CONFIG_PATH="${INSTALL_PKG_CONFIG_DIR}"

OPTIONAL_CPU_SUPPORT=""
case ${ARCH} in
    arm-v7a-neon | arm64-v8a)
        OPTIONAL_CPU_SUPPORT="--enable-arm-neon"
    ;;
    x86 | x86-64)
        OPTIONAL_CPU_SUPPORT="--enable-x86-aesni"
    ;;
esac

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURING IF REQUESTED
if [[ ${RECONF_nettle} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

./configure \
    --prefix=${BASEDIR}/prebuilt/android-$(get_target_build)/${LIB_NAME} \
    --enable-pic \
    --enable-static \
    --with-include-path=${BASEDIR}/prebuilt/android-$(get_target_build)/gmp/include \
    --with-lib-path=${BASEDIR}/prebuilt/android-$(get_target_build)/gmp/lib \
    --disable-shared \
    --disable-mini-gmp \
    --disable-assembler \
    --disable-openssl \
    --disable-gcov \
    --disable-documentation \
    ${OPTIONAL_CPU_SUPPORT} \
    --host=${TARGET_HOST} || exit 1

make -j$(get_cpu_count) || exit 1

# MANUALLY COPY PKG-CONFIG FILES
cp ./*.pc ${INSTALL_PKG_CONFIG_DIR}

make install || exit 1
