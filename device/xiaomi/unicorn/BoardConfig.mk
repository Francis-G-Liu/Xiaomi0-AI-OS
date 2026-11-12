#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Xiaomi 12S Pro (unicorn) board configuration for AOSP 17.
#
# AOSP builds ONLY the system side. The device layer and boot-side images are
# prebuilt from the original X-MiPort package (see assemble-super.sh / flash-all.sh).
#

# Architecture (SM8475: Cortex-X2/A710/A510, armv9)
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := generic

# Platform
TARGET_BOARD_PLATFORM := taro
TARGET_BOOTLOADER_BOARD_NAME := unicorn
TARGET_BOARD_INFO_FILE := device/xiaomi/unicorn/board-info.txt

# Kernel / boot: prebuilt from the port package, not built by AOSP
TARGET_NO_KERNEL := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 201326592
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# DTBO: prebuilt from the port package
BOARD_DTBOIMG_PARTITION_SIZE := 24117248
BOARD_PREBUILT_DTBOIMAGE := device/xiaomi/unicorn/prebuilt/dtbo/dtbo.img
BOARD_INCLUDE_RECOVERY_DTBO := true

# Partitions / filesystems (system side built by AOSP)
TARGET_RO_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_USERIMAGES_USE_F2FS := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_USES_METADATA_PARTITION := true
BOARD_FLASH_BLOCK_SIZE := 4096

# Dynamic partitions (only the partitions AOSP builds)
TARGET_USE_DYNAMIC_PARTITIONS := true
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := true
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 8589934592

# AB slots
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += system system_ext product

# AVB: off for the AOSP-built images; the device flashes the port's vbmeta and
# relies on the unlocked bootloader.
BOARD_AVB_ENABLE := false

# Recovery fstab (the real 12S Pro fstab)
TARGET_RECOVERY_FSTAB := device/xiaomi/unicorn/fstab.qcom

# No device-specific SELinux sources (the prebuilt vendor ships its own policy)