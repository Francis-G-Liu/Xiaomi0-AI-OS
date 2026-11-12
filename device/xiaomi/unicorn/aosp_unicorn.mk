#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Xiaomi 12S Pro (unicorn) product definition for AOSP 17.
#
# Strategy (unlocked BL):
#   - AOSP builds only the system side: system.img / system_ext.img / product.img
#   - The 12S Pro device layer (vendor / odm / vendor_dlkm / mi_ext) is kept as
#     prebuilt EROFS images under vendor/xiaomi/unicorn/prebuilt_images/
#   - boot / vendor_boot / dtbo / recovery / vbmeta / low-level firmware are the
#     untouched images from the original port package
#   - device/xiaomi/unicorn/assemble-super.sh glues everything into super.img
#   - device/xiaomi/unicorn/flash-all.sh flashes the full set
#

# Inherit from common AOSP config
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit vendor makefile (identity props)
$(call inherit-product-if-exists, vendor/xiaomi/unicorn/unicorn-vendor.mk)

# Device identifier
PRODUCT_NAME := aosp_unicorn
PRODUCT_DEVICE := unicorn
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Xiaomi 12S Pro

# Shipping API level: the prebuilt device layer is Android 12 (SDK 31)
PRODUCT_SHIPPING_API_LEVEL := 31

# Port bridge: the 12S Pro device layer identity wins over AOSP system identity
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.property_source_order=odm,vendor,product,system_ext,system \
    ro.product.mod_device=unicorn \
    ro.mi.os.version.name=OS4.0 \
    ro.mi.os.version.incremental=OS4.0.27.0.XEOCNXM \
    ro.mi.os.version.code=4

# Overlay
DEVICE_PACKAGE_OVERLAYS += \
    device/xiaomi/unicorn/overlay

# The real 12S Pro fstab is shipped inside the prebuilt vendor partition.
# A copy is kept here for reference and for `TARGET_RECOVERY_FSTAB`.