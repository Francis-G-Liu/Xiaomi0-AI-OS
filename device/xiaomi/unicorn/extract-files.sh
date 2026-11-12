#!/bin/bash
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Reproducibly extract the Xiaomi 12S Pro (unicorn) device layer from the
# X-MiPort_Mi12SPro_OS4 package into the AOSP source tree.
#
# Requirements: zstd, python3, fsck.erofs (homebrew erofs-utils)
#
# Usage:
#   device/xiaomi/unicorn/extract-files.sh
#
set -euo pipefail

AOSP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PORT_DIR="$AOSP_ROOT/X-MiPort_Mi12SPro_OS4"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LP_TOOL="$HERE/tools/lp.py"

WORK=/tmp/miport_repro
mkdir -p "$WORK/data" "$WORK/root" "$WORK/parts"

VENDOR_BASE="$AOSP_ROOT/vendor/xiaomi/unicorn"
DEV_BASE="$AOSP_ROOT/device/xiaomi/unicorn"

echo "=== [1/6] decompress super.img.zst (if needed) ==="
if [ ! -f "$WORK/data/super.img" ]; then
    if [ ! -f "$PORT_DIR/images/super.img" ]; then
        zstd -d -f "$PORT_DIR/images/super.img.zst" -o "$WORK/data/super.img"
        SUPER="$WORK/data/super.img"
    else
        SUPER="$PORT_DIR/images/super.img"
    fi
else
    SUPER="$WORK/data/super.img"
fi

echo "=== [2/6] split logical partitions ==="
python3 -I "$LP_TOOL" extract "$SUPER" "$WORK/parts"

echo "=== [3/6] unpack EROFS trees ==="
for p in vendor vendor_dlkm odm mi_ext; do
    if [ ! -d "$WORK/root/$p/." ]; then
        fsck.erofs --extract="$WORK/root/$p" "$WORK/parts/${p}_a.img" >/dev/null 2>&1 || true
    else
        echo "  skip $p (already extracted)"
    fi
done

echo "=== [4/6] restore blobs into vendor/xiaomi/unicorn ==="
mkdir -p "$VENDOR_BASE/proprietary" "$VENDOR_BASE/prebuilt_images"
for p in vendor vendor_dlkm odm mi_ext; do
    [ -d "$WORK/root/$p/." ] && cp -a "$WORK/root/$p"/. "$VENDOR_BASE/proprietary/$p/"
    cp -a "$WORK/parts/${p}_a.img" "$VENDOR_BASE/prebuilt_images/${p}_a.img"
done
# build.prop shortcuts
cp "$VENDOR_BASE/proprietary/vendor/etc/build.prop" "$VENDOR_BASE/proprietary/vendor_build.prop" 2>/dev/null || true
cp "$VENDOR_BASE/proprietary/odm/etc/build.prop" "$VENDOR_BASE/proprietary/odm_build.prop" 2>/dev/null || true
# regenerate file manifest
( cd "$VENDOR_BASE/proprietary" && find vendor vendor_dlkm odm mi_ext \( -type f -o -type l \) ) \
    | sort > "$VENDOR_BASE/proprietary-files.txt"
echo "  blobs: $(wc -l < "$VENDOR_BASE/proprietary-files.txt") entries"

echo "=== [5/6] kernel + boot-side images ==="
mkdir -p "$DEV_BASE/prebuilt/kernel" "$DEV_BASE/prebuilt/dtbo" "$DEV_BASE/prebuilt/boot"
python3 -I - "$PORT_DIR/images/boot_official.img" "$DEV_BASE/prebuilt/kernel/Image" <<'PY'
import struct,sys
p,out=sys.argv[1],sys.argv[2]
d=open(p,'rb').read()
ks=struct.unpack_from('<I',d,8)[0]
i=d.find(b'ARMd')
assert i>0, "no kernel image magic"
start=i-0x38
assert start%4096==0, "kernel not page aligned"
open(out,'wb').write(d[start:start+ks])
print("  kernel:",ks,"bytes")
PY
cp "$PORT_DIR/images/dtbo.img" "$DEV_BASE/prebuilt/dtbo/dtbo.img"
for b in boot_official vendor_boot recovery vbmeta vbmeta_system; do
    [ -f "$PORT_DIR/images/$b.img" ] && cp "$PORT_DIR/images/$b.img" "$DEV_BASE/prebuilt/boot/$b.img"
done

echo "=== [6/6] keep the real fstab on the device tree ==="
cp "$VENDOR_BASE/proprietary/vendor/etc/fstab.qcom" "$DEV_BASE/fstab.qcom"

echo "=== done ==="
du -sh "$VENDOR_BASE" "$DEV_BASE/prebuilt" 2>/dev/null