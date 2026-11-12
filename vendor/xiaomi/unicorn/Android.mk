#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# The 12S Pro device layer is shipped as prebuilt EROFS partition images
# (vendor / odm / vendor_dlkm / mi_ext) and assembled into super by
# device/xiaomi/unicorn/assemble-super.sh. No individual blob modules are
# needed here; the full extracted trees under proprietary/ are kept for
# reference and repacking.

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),unicorn)
# intentionally empty
endif
