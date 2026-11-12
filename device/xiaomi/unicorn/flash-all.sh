#!/bin/bash
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Flash a built Xiaomi 12S Pro (unicorn) system to the device.
#
# Boot-side images (boot / vendor_boot / dtbo / recovery / vbmeta*) are taken
# from the original port package, because the 12S Pro uses prebuilt firmware.
# The super image is the one assembled by assemble-super.sh.
#
# Usage:
#   device/xiaomi/unicorn/flash-all.sh [-w]
#     -w   wipe userdata/metadata (first flash / encryption change)
#
set -e

AOSP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PORT="$AOSP_ROOT/X-MiPort_Mi12SPro_OS4/images"
PRODUCT_OUT="${PRODUCT_OUT:-$AOSP_ROOT/out/target/product/unicorn}"
BOOT_DIR="$AOSP_ROOT/device/xiaomi/unicorn/prebuilt/boot"
SUPER_IMG="$PRODUCT_OUT/super_assembly/super.img"
FB="fastboot"

if [ "$1" = "-w" ]; then WIPE=1; else WIPE=0; fi

echo "== Waiting for device in fastboot =="
$FB getvar product 2>&1 | grep -i unicorn || {
    echo "WARNING: device product is not UNICORN. Continue? [y/N]"
    read -r a; [ "$a" = "y" ] || exit 1
}

echo "== Flashing boot-side images =="
# Write both A/B slots for every image, exactly as the port's update-binary does
# (it writes by-name/<part>_a and by-name/<part>_b). Slots are written
# explicitly so a partial/failed active slot can't brick the device.
for slot in _a _b; do
    $FB flash boot${slot}          "$BOOT_DIR/boot_official.img"      || true
    $FB flash vendor_boot${slot}    "$BOOT_DIR/vendor_boot.img"        || true
    $FB flash dtbo${slot}           "$BOOT_DIR/dtbo.img"               || true
    $FB flash recovery${slot}       "$BOOT_DIR/recovery.img"           || true
    $FB --disable-verity --disable-verification flash vbmeta${slot}        "$BOOT_DIR/vbmeta.img"        || true
    $FB --disable-verity --disable-verification flash vbmeta_system${slot} "$BOOT_DIR/vbmeta_system.img" || true
done

if [ -f "$PORT/xbl.img" ]; then
    echo "== Flashing low-level firmware (xbl/abl/tz/hyp/modem/...) =="
    for slot in _a _b; do
        for p in xbl_ramdump xbl_config xbl vm-bootsys uefisecapp uefi tz shrm \
                 qupfw modem keymaster imagefv hyp featenabler dsp devcfg cpucp \
                 bluetooth aop aop_config abl; do
            [ -f "$PORT/$p.img" ] && $FB flash ${p}${slot} "$PORT/$p.img" || true
        done
    done
fi

echo "== Flashing super =="
if [ ! -f "$SUPER_IMG" ]; then
    echo "ERROR: $SUPER_IMG not found. Run assemble-super.sh first." >&2
    exit 1
fi
$FB flash super "$SUPER_IMG"

if [ "$WIPE" = "1" ]; then
    echo "== Wiping userdata / metadata =="
    $FB erase userdata || true
    $FB erase metadata || true
fi

echo "== Switching to slot a and rebooting =="
$FB set_active a || true
$FB reboot
