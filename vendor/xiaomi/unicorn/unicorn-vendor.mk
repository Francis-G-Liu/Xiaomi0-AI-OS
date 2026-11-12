#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Vendor makefile for Xiaomi 12S Pro (unicorn).
#
# The device layer (vendor / odm / vendor_dlkm / mi_ext) is kept as prebuilt
# EROFS images under vendor/xiaomi/unicorn/prebuilt_images/ and assembled into
# super by device/xiaomi/unicorn/assemble-super.sh.
#
# The full extracted blob trees live under vendor/xiaomi/unicorn/proprietary/
# for reference / repacking.

PRODUCT_SOONG_NAMESPACES += \
    vendor/xiaomi/unicorn

# Identity properties (also carried by the prebuilt vendor/odm build.prop)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.product.vendor.device=unicorn \
    ro.product.vendor.name=unicorn \
    ro.product.vendor.model=2206122SC \
    ro.product.vendor.marketname=Xiaomi 12S Pro \
    ro.product.vendor.brand=Xiaomi \
    ro.product.vendor.manufacturer=Xiaomi
