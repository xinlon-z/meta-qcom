SECTION = "kernel"

DESCRIPTION = "Linux ${PV} kernel for QCOM devices"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

inherit kernel cml1

COMPATIBLE_MACHINE = "(qcom)"

LINUX_VERSION ?= "6.18+6.19-rc4"

PV = "${LINUX_VERSION}+git"

# tag: qcom-next-6.19-rc4-20260112
SRCREV ?= "65bb05266d477c9f7b06bc275bd622dbed08a53b"

SRCBRANCH ?= "nobranch=1"
SRCBRANCH:class-devupstream ?= "branch=qcom-next"

SRC_URI = "git://github.com/qualcomm-linux/kernel.git;${SRCBRANCH};protocol=https \
           file://configs/bsp-additions.cfg \
           ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'file://selinux.cfg', '', d)} \
           file://0001-FROMLIST-dt-bindings-arm-qcom-Document-PURWA-IOT-EVK.patch \
           file://0002-FROMLIST-firmware-qcom-scm-Allow-QSEECOM-on-PURWA-IO.patch \
           file://0003-FROMLIST-arm64-dts-qcom-Add-PURWA-IOT-SOM-platform.patch \
           file://0004-FROMLIST-arm64-dts-qcom-Add-base-PURWA-IOT-EVK-board.patch \
           file://0005-QCLINUX-arm64-dts-qcom-workaround-for-TPM-pins.patch \
           "

# Additional kernel configs.

# To build tip of qcom-next branch set preferred
# virtual/kernel provider to 'linux-qcom-next-upstream'
BBCLASSEXTEND = "devupstream:target"
PN:class-devupstream = "linux-qcom-next-upstream"
SRCREV:class-devupstream ?= "${AUTOREV}"

S = "${UNPACKDIR}/${BP}"

KBUILD_DEFCONFIG ?= "defconfig"
KBUILD_DEFCONFIG:qcom-armv7a = "qcom_defconfig"

KBUILD_CONFIG_EXTRA = "${@bb.utils.contains('DISTRO_FEATURES', 'hardened', '${S}/kernel/configs/hardening.config', '', d)}"
KBUILD_CONFIG_EXTRA:append:aarch64 = " ${S}/arch/arm64/configs/prune.config"
KBUILD_CONFIG_EXTRA:append:aarch64 = " ${S}/arch/arm64/configs/qcom.config"

do_configure:prepend() {
    # Use a copy of the 'defconfig' from the actual repo to merge fragments
    cp ${S}/arch/${ARCH}/configs/${KBUILD_DEFCONFIG} ${B}/.config

    # Merge fragment for QCOM value add features
    ${S}/scripts/kconfig/merge_config.sh -m -O ${B} ${B}/.config ${KBUILD_CONFIG_EXTRA} ${@" ".join(find_cfgs(d))}
}
