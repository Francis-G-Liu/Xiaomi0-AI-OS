#!/bin/bash
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Assemble a flashable super image for Xiaomi 12S Pro (unicorn).
#
# Built by AOSP:      system.img, system_ext.img, product.img
# Prebuilt (device):  vendor, odm, vendor_dlkm, mi_ext  (EROFS, from the port)
#
# Usage:
#   source build/envsetup.sh && lunch aosp_unicorn-trunk_staging-userdebug && m
#   device/xiaomi/unicorn/assemble-super.sh
#
set -e

AOSP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PRODUCT_OUT="${PRODUCT_OUT:-$AOSP_ROOT/out/target/product/unicorn}"
PREBUILT="$AOSP_ROOT/vendor/xiaomi/unicorn/prebuilt_images"
OUT="$PRODUCT_OUT/super_assembly"

SUPER_SIZE=9126805504
GROUP_SIZE=8589934592
GROUP_NAME="qti_dynamic_partitions_a"
METADATA_SIZE=65536
METADATA_SLOTS=3

mkdir -p "$OUT"

# Locate lpmake
LPMAKE="$(command -v lpmake || true)"
if [ -z "$LPMAKE" ]; then
    LPMAKE="$AOSP_ROOT/out/host/darwin-arm64/bin/lpmake"
fi
if [ ! -x "$LPMAKE" ]; then
    echo "ERROR: lpmake not found. Run 'm lpmake' first." >&2
    exit 1
fi

# macOS stat (bytes) helper
fsize() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }

round4k() { echo $(( (($1) + 4095) / 4096 * 4096 )); }

PARTITIONS=(
    "system:$PRODUCT_OUT/system.img"
    "system_ext:$PRODUCT_OUT/system_ext.img"
    "product:$PRODUCT_OUT/product.img"
    "vendor:$PREBUILT/vendor_a.img"
    "odm:$PREBUILT/odm_a.img"
    "vendor_dlkm:$PREBUILT/vendor_dlkm_a.img"
    "mi_ext:$PREBUILT/mi_ext_a.img"
)

ARGS=()
for entry in "${PARTITIONS[@]}"; do
    name="${entry%%:*}"
    img="${entry#*:}"
    if [ ! -f "$img" ]; then
        echo "ERROR: missing image for $name: $img" >&2
        exit 1
    fi
    sz=$(fsize "$img")
    sz=$(round4k "$sz")
    echo "  $name  $(printf '%.1f' "$(echo "$sz/1048576" | bc -l 2>/dev/null || echo 0)") MiB"
    ARGS+=(--partition "$name:readonly:$sz:$GROUP_NAME" --image "$name=$img")
done

echo "=== lpmake: assembling super.img ==="
"$LPMAKE" \
    --metadata-size "$METADATA_SIZE" \
    --metadata-slots "$METADATA_SLOTS" \
    --device "super:$SUPER_SIZE" \
    --alignment 1048576 \
    --group "$GROUP_NAME:$GROUP_SIZE" \
    "${ARGS[@]}" \
    --sparse \
    --output "$OUT/super.img"

echo "=== done: $OUT/super.img ==="
ls -lh "$OUT/super.img"
