#!/bin/bash

set -e

USE_CCACHE=1
DEVICE=${1}
TARGET_BUILD_NUMBER=305
BUILD_TOOLS="../OM5Z_build_tools"
TIMESTAMP=`date +"%Y%m%d"`
export ARCH=arm64


if [ -z ${DEVICE} ]; then
    echo "Usage: ./build.sh device"
    echo "For example: ./build.sh ivy_dsds"
    exit 1
fi

if [ ! -d "${BUILD_TOOLS}" ]; then
    echo "Build tools not found, aborting."
    exit 1
fi

case ${DEVICE} in
    ivy)
        VARIANT=E6553
        ;;
    ivy_dsds)
        VARIANT=E6533
        ;;
    sumire)
        VARIANT=E6653
        ;;
    sumire_dsds)
        VARIANT=E6653
        ;;
    suzuran)
        VARIANT=E5823
        ;;
    *)
        echo "Sorry, but the ${DEVICE} device is not supported."
        exit 1
esac

RAMDISK_DIR=ramdisk_${VARIANT}_${TARGET_BUILD_NUMBER}
RAMDISK=ramdisk.${DEVICE}.cpio.gz
BOOT_IMAGE=${BUILD_TOOLS}/boot_${DEVICE}_OM5Z_${TARGET_BUILD_NUMBER}_${TIMESTAMP}.img

if [ -z ${JENKINS_BUILD+x} ]; then
    JENKINS_BUILD=false
fi

if [ $JENKINS_BUILD != "true" ]; then
    export PATH=/media/myself5/AOSP/commit/aarch64-linux-android-4.9-gcc/bin/:$PATH
fi

### See prefix of file names in the toolchain's bin directory
export CROSS_COMPILE=aarch64-linux-android-

echo "Building Sony ${VARIANT} (${DEVICE})"
make mrproper
make mm_${DEVICE}_defconfig
make -j$(grep -c ^processor /proc/cpuinfo)

# Pack ramdisk
${BUILD_TOOLS}/mkbootfs ${BUILD_TOOLS}/${RAMDISK_DIR} | gzip -n -f > ${BUILD_TOOLS}/${RAMDISK}

### ${VARIANT}
${BUILD_TOOLS}/bootimg mkimg --cmdline "androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 boot_cpus=0-5 dwc3_msm.prop_chg_detect=Y coherent_pool=2M dwc3_msm.hvdcp_max_current=1500" --base 0x00000000 --kernel arch/arm64/boot/Image.gz-dtb --ramdisk ${BUILD_TOOLS}/${RAMDISK} --ramdisk_offset 0x02000000 --pagesize 4096 -o ${BOOT_IMAGE} --tags_offset 0x01E00000
echo "${BOOT_IMAGE} has been built successfully."
