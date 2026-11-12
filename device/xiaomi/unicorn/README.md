# Xiaomi 12S Pro (unicorn) Device Configuration

## Overview

This device tree builds the **system side only** (system / system_ext / product)
for the Xiaomi 12S Pro (codename: unicorn) onto AOSP 17 (trunk_staging).

**Device Information:**
- **Model**: Xiaomi 12S Pro (2206122SC)
- **Codename**: unicorn
- **SoC**: Qualcomm Snapdragon 8+ Gen 1 (SM8475, "taro")
- **Architecture**: arm64
- **Bootloader**: unlocked (needed: vbmeta verification is disabled)

## Porting Strategy

The shipped port package `X-MiPort_Mi12SPro_OS4` straps a HyperOS OS4 (Android 17,
codename `missi`) system onto the 12S Pro's Android 12 (SDK 31) device layer.

Because an Android 12 vendor cannot be re-homed onto a pure AOSP 17 system build
(no vendor compat / VNDK support in the AOSP 17 branch), this tree keeps the
**device layer as-is** and only replaces the system side:

```
┌─────────────────────────────────────────────────────┐
│  system / system_ext / product   ← built by AOSP 17 │
├─────────────────────────────────────────────────────┤
│  vendor / odm / vendor_dlkm / mi_ext                │
│    ← prebuilt EROFS images from the port package    │
├─────────────────────────────────────────────────────┤
│  boot / vendor_boot / dtbo / vbmeta* / firmware     │
│    ← untouched images from the port package         │
└─────────────────────────────────────────────────────┘
```

- AOSP builds `system.img`, `system_ext.img`, `product.img` (erofs).
- `vendor_a.img`, `odm_a.img`, `vendor_dlkm_a.img`, `mi_ext_a.img` are the
  unmodified EROFS images extracted from the package (`prebuilt_images/`).
- `assemble-super.sh` re-combines all 7 logical partitions into one
  `super.img` with `lpmake`.
- `flash-all.sh` flashes boot-side + firmware images and the super image.

This is the closest to a functional AOSP-17-based build that is possible with
the unlocked-bootloader constraint: no vendor source, an Android 12 HAL set, and
a prebuilt kernel in `boot`.

## Directory Layout

```
device/xiaomi/unicorn/
├── AndroidProducts.mk        # lunch choices (aosp_unicorn-trunk_staging-{user,userdebug,eng})
├── aosp_unicorn.mk           # product definition (AOSP system side)
├── BoardConfig.mk            # board configuration (TARGET_NO_KERNEL := true)
├── fstab.qcom                # the real 12S Pro fstab (copied from the image)
├── extract-files.sh          # reproducible extraction from X-MiPort_Mi12SPro_OS4
├── assemble-super.sh         # build super.img from AOSP + prebuilt images
├── flash-all.sh              # fastboot flashing (boot + firmware + super)
├── board-info.txt
├── configs/manifest_unicorn.xml   # VINTF manifest (reference)
├── tools/lp.py               # liblp metadata parser / super.img extractor
├── overlay/                  # resource overlays
└── prebuilt/
    ├── kernel/Image          # kernel, extracted from boot_official.img
    ├── dtbo/dtbo.img
    └── boot/                 # boot_official, vendor_boot, recovery, vbmeta*
```

```
vendor/xiaomi/unicorn/
├── unicorn-vendor.mk         # vendor identity properties
├── proprietary-files.txt     # manifest of every extracted blob (~5.3k entries)
├── proprietary/{vendor,odm,vendor_dlkm,mi_ext}   # unpacked vendor trees
└── prebuilt_images/          # the 4 EROFS partition images used by assemble-super.sh
```

## Building

### 1. Initialize

```bash
cd /Users/francisliu/Documents/个人新企划/Xiaomi_AI-OS
source build/envsetup.sh
```

### 2. Lunch

```bash
lunch aosp_unicorn-trunk_staging-userdebug
```

### 3. Build (system side)

```bash
m systemimage system_extimage productimage
```

> Full tight build of a generic AOSP product needs >100 GB of disk; on this
> machine only the explicit image targets above are practical. `assemble-super.sh`
> documents the disk requirement for a complete flashable super.

### 4. Rebuild super.img

```bash
# requires lpmake to be built on the host (m lpmake)
device/xiaomi/unicorn/assemble-super.sh
```

## Partition Layout (from the package's super.img)

| Partition | Size (bytes) | Filesystem | Build |
|-----------|-------------:|------------|-------|
| boot | 201326592 | prebuilt image | package |
| vendor_boot | 100663296 | prebuilt image | package |
| dtbo | 24117248 | prebuilt image | package |
| super | 9126805504 | dynamic partitions | assembled |
| ├─ system | 952791040 | erofs | **AOSP** |
| ├─ system_ext | 911081472 | erofs | **AOSP** |
| ├─ product | 3678457856 | erofs | **AOSP** |
| ├─ vendor | 1716420608 | erofs | package |
| ├─ vendor_dlkm | 29876224 | erofs | package |
| ├─ odm | 1032192 | erofs | package |
| └─ mi_ext | 135168 | erofs | package |

## Flashing (unlocked bootloader)

```bash
# fastboot into bootloader, then:
adb reboot bootloader
device/xiaomi/unicorn/flash-all.sh -w      # -w wipes userdata/metadata
```

`flash-all.sh` writes both A/B slots for all firmware and boot-side images,
flashes the (disabled-verity) vbmeta, then flashes the assembled super image.

## Known Limitations

1. **No vendor compatibility layer**: an Android-12-era vendor partition cannot
   be driven by a stock AOSP 17 system (VNDK/vendor-HAL compatibility was
   removed upstream). HALs staked into `/vendor` may not start against the
   AOSP framework. This is the fundamental constraint of this port.
2. **Android 12 system semantics**: framework behavior differs from the HyperOS
   system the vendor was originally paired with (see `PORTING_SUMMARY.md`).
3. **Storage**: full build not feasible on this machine; build only
   system/system_ext/product, keep vendor images prebuilt.
4. **SELinux**: device-side policy comes from the prebuilt vendor `sepolicy`
   directory inside the vendor images; no new policy is compiled in this tree
   (which is why `sepolicy/` is intentionally absent here).

## Verification

```bash
adb shell getprop ro.product.device     # unicorn
adb shell getprop ro.product.model      # Xiaomi 12S Pro
adb shell getprop ro.product.property_source_order  # odm,vendor,product,system_ext,system
```

## License

```
Copyright (C) 2024 The LineageOS Project
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

## Credits

- **HyperOS Port**: X-MiPort team for the original adaptation layer and the
  prebuilt images this tree inherits.
- **AOSP**: Android Open Source Project.
- **LineageOS**: Device tree structure reference.