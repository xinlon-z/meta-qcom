# Copyright (c) 2023-2024 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

inherit image_types

IMAGE_TYPES += "qcomflash"

QCOM_BOOT_FIRMWARE ?= ""

QCOM_ESP_IMAGE ?= "${@bb.utils.contains("MACHINE_FEATURES", "efi", "esp-qcom-image", "", d)}"
QCOM_ESP_FILE ?= "${@'${DEPLOY_DIR_IMAGE}/${QCOM_ESP_IMAGE}-${MACHINE}${IMAGE_NAME_SUFFIX}.vfat' if d.getVar('QCOM_ESP_IMAGE') else ''}"

# When not specified, assume the board supports FIT-based
# multi-DTB and mention this as the default DTB to be flashed.
QCOM_DTB_DEFAULT ?= "multi-dtb"
QCOM_DTB_FILE ?= "dtb.bin"

QCOM_BOOT_FILES_SUBDIR ?= ""
QCOM_PARTITION_FILES_SUBDIR ??= "${QCOM_BOOT_FILES_SUBDIR}"
QCOM_PARTITION_FILES_SUBDIR_SPINOR ??= ""

QCOM_PARTITION_CONF ?= "qcom-partition-conf"

IMAGE_QCOMFLASH_FS_TYPE ??= "ext4"

QCOMFLASH_DIR = "${IMGDEPLOYDIR}/${IMAGE_NAME}.qcomflash"
IMAGE_CMD:qcomflash = "create_qcomflash_pkg"
do_image_qcomflash[dirs] = "${QCOMFLASH_DIR}"
do_image_qcomflash[cleandirs] = "${QCOMFLASH_DIR}"
do_image_qcomflash[depends] += "${@ ['', '${QCOM_PARTITION_CONF}:do_deploy'][d.getVar('QCOM_PARTITION_CONF') != '']} \
                                ${@ ['', '${QCOM_BOOT_FIRMWARE}:do_deploy'][d.getVar('QCOM_BOOT_FIRMWARE') != '']} \
                                virtual/kernel:do_deploy \
				${@'virtual/bootloader:do_deploy' if d.getVar('PREFERRED_PROVIDER_virtual/bootloader') else  ''} \
				${@'${QCOM_ESP_IMAGE}:do_image_complete' if d.getVar('QCOM_ESP_IMAGE') != '' else  ''} \
				${@'abl2esp:do_deploy' if d.getVar('ABL_SIGNATURE_VERSION') else  ''}"
IMAGE_TYPEDEP:qcomflash += "${IMAGE_QCOMFLASH_FS_TYPE}"

deploy_partition_files() {
    for pbin in $1/gpt_main*.bin $1/gpt_backup*.bin \
                $1/gpt_both*.bin $1/zeros_*.bin \
                $1/rawprogram[0-9].xml $1/patch*.xml ; do
        install -m 0644 ${pbin} $2
    done

    if [ -e "$1/contents.xml" ]; then
        install -m 0644 "$1/contents.xml" $2/contents.xml
    fi
}

create_qcomflash_pkg() {
    # 1. 获取路径列表（已知不为空）
    local part_list="${QCOM_PARTITION_FILES_SUBDIR}"
    # 计算路径数量
    local count=$(echo ${part_list} | wc -w)

    # 2. 遍历每一个存储分区配置
    for part_dir in ${part_list}; do
        # 获取当前存储类型的名称 (如 ufs, nvme, spinor)
        local storage_type=$(basename "${part_dir}")
        local dest_dir="."

        # 3. 确定安装目标目录
        # 如果有多个路径，则创建对应子目录；如果是单个路径，保持在根目录 (.)
        if [ "$count" -gt 1 ]; then
            dest_dir="${storage_type}"
            # 清理旧数据并创建新目录
            rm -rf "${dest_dir}"
            install -d "${dest_dir}"
        fi

        bbnote "Generating QCOM flash package: ${storage_type} -> ${dest_dir}"

        # --- [A] 基础镜像 (所有类型通用) ---
        # Rootfs
        install -m 0644 ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMAGE_QCOMFLASH_FS_TYPE} "${dest_dir}/rootfs.img"

        # Kernel (vmlinux)
        if [ -e "${DEPLOY_DIR_IMAGE}/vmlinux" ]; then
            install -m 0644 "${DEPLOY_DIR_IMAGE}/vmlinux" "${dest_dir}/vmlinux"
        fi

        # ESP / EFI (如果有)
        if [ -n "${QCOM_ESP_FILE}" ]; then
            install -m 0644 ${QCOM_ESP_FILE} "${dest_dir}/efi.bin"
        fi

        # --- [B] 分区表 XML (Partition Tables) ---
        if [ -d "${part_dir}" ]; then
            deploy_partition_files "${part_dir}" "${dest_dir}"
        fi

        # --- [C] 固件与 Boot Images (区分 Spinor 和 普通存储) ---

        if [ "$storage_type" = "spinor" ]; then
            # ==========================================
            # [CASE 1] SPINOR 特殊处理
            # ==========================================
            local spinor_src="${DEPLOY_DIR_IMAGE}/${QCOM_BOOT_FILES_SUBDIR}/spinor"

            if [ -d "${spinor_src}" ]; then
                # 1. 拷贝所有 Spinor 专用固件 (包含 xbl, aop, non-hlos 等)
                find "${spinor_src}" -maxdepth 1 -type f -exec install -m 0644 {} "${dest_dir}" \;

                # 2. CDT (Spinor): 确保使用 spinor 目录下的 CDT
                if [ -n "${QCOM_CDT_FILE}" ] && [ -e "${spinor_src}/${QCOM_CDT_FILE}.bin" ]; then
                    install -m 0644 "${spinor_src}/${QCOM_CDT_FILE}.bin" "${dest_dir}/cdt.bin"
                fi

                # 3. DTB (Spinor): 通常只放默认的一个 dtb.bin
                if [ -n "${QCOM_DTB_FILE}" ] && [ -n "${QCOM_DTB_DEFAULT}" ]; then
                     install -m 0644 "${DEPLOY_DIR_IMAGE}/dtb-${QCOM_DTB_DEFAULT}-image.vfat" "${dest_dir}/${QCOM_DTB_FILE}"
                fi

                # 4. Programmer (xbl_s_devprg_ns.melf): 上面的 find 可能已覆盖，这里确保万无一失
                find "${spinor_src}" -maxdepth 1 -type f -name 'xbl_s_devprg_ns.melf' -exec install -m 0644 {} "${dest_dir}" \;

            else
                bbwarn "Spinor storage requested but source directory ${spinor_src} not found!"
            fi

        else
            # ==========================================
            # [CASE 2] 标准存储处理 (UFS / NVMe)
            # ==========================================
            local common_src="${DEPLOY_DIR_IMAGE}/${QCOM_BOOT_FILES_SUBDIR}"

            if [ -n "${QCOM_BOOT_FILES_SUBDIR}" ] && [ -d "${common_src}" ]; then
                # 1. 拷贝通用固件 (按后缀过滤)
                for bfw in `find ${common_src} -maxdepth 1 -type f \
                        \( -name '*.elf' ! -name 'abl2esp*.elf' ! -name 'xbl_config*.elf' \) -o \
                        -name '*.mbn*' -o \
                        -name '*.fv' -o \
                        -name 'cdt_*.bin' -o \
                        -name 'logfs_*.bin' -o \
                        -name 'sec.dat'` ; do
                    install -m 0644 ${bfw} "${dest_dir}/"
                done

                # 2. CDT (通用)
                if [ -n "${QCOM_CDT_FILE}" ] && [ -e "${common_src}/${QCOM_CDT_FILE}.bin" ]; then
                    install -m 0644 "${common_src}/${QCOM_CDT_FILE}.bin" "${dest_dir}/cdt.bin"
                fi

                # 3. DTB (通用): 拷贝所有 dtb variants
                if [ -n "${QCOM_DTB_DEFAULT}" ] && \
                   [ -f "${DEPLOY_DIR_IMAGE}/dtb-${QCOM_DTB_DEFAULT}-image.vfat" ]; then

                    # 默认 DTB 重命名为 dtb.bin
                    install -m 0644 "${DEPLOY_DIR_IMAGE}/dtb-${QCOM_DTB_DEFAULT}-image.vfat" "${dest_dir}/${QCOM_DTB_FILE}"

                    # 拷贝其余所有 DTB 镜像
                    for dtbimg in ${DEPLOY_DIR_IMAGE}/dtb-*-image.vfat; do
                        install -m 0644 ${dtbimg} "${dest_dir}/"
                    done
                fi

                # 4. xbl_config & abl2esp
                local xbl_config="xbl_config.elf"
                if ${@bb.utils.contains('DISTRO_FEATURES', 'kvm', 'true', 'false', d)}; then
                    xbl_config="xbl_config_kvm.elf"
                fi
                if [ -f "${common_src}/${xbl_config}" ]; then
                    install -m 0644 "${common_src}/${xbl_config}" "${dest_dir}/xbl_config.elf"
                fi
                if [ -e "${DEPLOY_DIR_IMAGE}/abl2esp-${ABL_SIGNATURE_VERSION}.elf" ]; then
                    install -m 0644 "${DEPLOY_DIR_IMAGE}/abl2esp-${ABL_SIGNATURE_VERSION}.elf" "${dest_dir}/"
                fi

                # 5. Legacy Boot Images (boot.img)
                # 这部分逻辑是从原文件保留下来的，主要针对非 EFI 启动或旧式启动
                if [ -n "${QCOM_DTB_DEFAULT}" ]; then
                    if [ -e "${DEPLOY_DIR_IMAGE}/boot-initramfs-${QCOM_DTB_DEFAULT}-${MACHINE}.img" ]; then
                        install -m 0644 "${DEPLOY_DIR_IMAGE}/boot-initramfs-${QCOM_DTB_DEFAULT}-${MACHINE}.img" "${dest_dir}/boot.img"
                    elif [ -e "${DEPLOY_DIR_IMAGE}/boot-${QCOM_DTB_DEFAULT}-${MACHINE}.img" ]; then
                        install -m 0644 "${DEPLOY_DIR_IMAGE}/boot-${QCOM_DTB_DEFAULT}-${MACHINE}.img" "${dest_dir}/boot.img"
                    fi
                fi
                if [ ! -e "${dest_dir}/boot.img" ] && [ -e "${DEPLOY_DIR_IMAGE}/boot-${MACHINE}.img" ]; then
                    install -m 0644 "${DEPLOY_DIR_IMAGE}/boot-${MACHINE}.img" "${dest_dir}/boot.img"
                fi
            fi
        fi

    done

    # 4. 打包生成 (Tarball)
    # 此时目录结构已就绪，一次性打包

    ln -rsf ${QCOMFLASH_DIR} ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.qcomflash

    ${IMAGE_CMD_TAR} --sparse --numeric-owner --transform="s,^\./,${IMAGE_BASENAME}-${MACHINE}/," -cf- . \
        | gzip -f -9 -n -c --rsyncable > ${IMGDEPLOYDIR}/${IMAGE_NAME}.qcomflash.tar.gz

    ln -sf ${IMAGE_NAME}.qcomflash.tar.gz ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.qcomflash.tar.gz
}

create_qcomflash_pkg[vardepsexclude] += "DATETIME"
