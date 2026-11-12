# Xiaomi 12S Pro (unicorn) AOSP 17 移植项目

## 📋 项目概述

本项目将小米 12S Pro 的 HyperOS OS4 适配层完整移植到 AOSP 17 源码树，为后续系统定制提供基础。

**设备信息：**
- **型号**: 小米 12S Pro (2206122SC)
- **代号**: unicorn
- **SoC**: 骁龙 8+ Gen 1 (SM8475)
- **架构**: arm64
- **内核**: 5.10.236-android12-9
- **供应商**: 小米

## 🏗️ 移植架构

### 分层设计

```
┌─────────────────────────────────────────┐
│  AOSP 17 System (Android 17/SDK 37)     │  ← 现代系统层
├─────────────────────────────────────────┤
│  Vendor Layer (Android 12/SDK 31)       │  ← 12S Pro 硬件抽象层
│  - HALs (相机、传感器、显示)            │
│  - 固件                                 │
│  - 内核模块                             │
└─────────────────────────────────────────┘
```

### 关键机制

**属性覆盖顺序**：通过 `ro.product.property_source_order=odm,vendor,product,system_ext,system` 实现设备身份识别，使 Android 17 系统层能正确识别为 12S Pro。

## 📁 目录结构

### 设备树 (`device/xiaomi/unicorn/`)

```
device/xiaomi/unicorn/
├── AndroidProducts.mk            # lunch 选择（aosp_unicorn-trunk_staging-{user,userdebug,eng}）
├── aosp_unicorn.mk               # 产品定义（仅 AOSP 系统侧）
├── BoardConfig.mk                # 板级配置（TARGET_NO_KERNEL := true）
├── fstab.qcom                    # 12S Pro 真实 fstab（从镜像原样复制）
├── extract-files.sh              # 可复现提取脚本
├── assemble-super.sh             # 用 lpmake 组装 super.img
├── flash-all.sh                  # fastboot 刷机（boot + 固件 + super）
├── board-info.txt
├── configs/
│   └── manifest_unicorn.xml      # VINTF 清单（参考用）
├── tools/lp.py                   # liblp 元数据解析器 / super.img 提取器
├── overlay/                      # 资源覆盖
└── prebuilt/                     # 预编译镜像
    ├── kernel/Image              # 内核（从 boot 镜像提取）
    ├── dtbo/dtbo.img
    └── boot/                     # boot_official / vendor_boot / recovery / vbmeta*
```

### 供应商目录 (`vendor/xiaomi/unicorn/`)

```
vendor/xiaomi/unicorn/
├── unicorn-vendor.mk             # 供应商身份属性
├── proprietary-files.txt         # 全部提取 blob 清单（约 5.3k 条）
├── proprietary/                  # 解包后的供应商树
│   ├── vendor/                   # 1.7GB, 完整 HAL + 固件 + fstab + sepolicy
│   ├── vendor_dlkm/              # 内核模块分区树
│   ├── odm/                      # ODM 配置
│   └── mi_ext/                   # 小米扩展层
└── prebuilt_images/              # 4 个 EROFS 分区镜像（assemble-super.sh 使用）
    ├── vendor_a.img
    ├── vendor_dlkm_a.img
    ├── odm_a.img
    └── mi_ext_a.img
```

### 构建策略

- **AOSP 构建**：`system.img` / `system_ext.img` / `product.img`（erofs）
- **预编译保留**：vendor / odm / vendor_dlkm / mi_ext 可从移植包原样提取并
  原封不动地装进 super（`extract-files.sh` 一步到位的全量适配）
- **boot 侧**：boot / vendor_boot / dtbo / recovery / vbmeta 全部使用移植包原始镜像
- **解锁 BL + 关闭验证**：flash 时 `fastboot --disable-verity --disable-verification flash vbmeta*`

## 📊 提取文件统计

| 类别 | 大小 | 文件数 | 说明 |
|------|------|--------|------|
| 内核 | 45MB | 1 | 5.10.236-android12-9 |
| DTBO | 23MB | 1 | 设备树覆盖 |
| 相机 | 643MB | 574 | HAL、传感器、调校、固件 |
| 内核模块 | 79MB | 311 | .ko 驱动模块 |
| 固件 | 39MB | 321 | 触控、音频、显示等 |
| 显示 | 27MB | - | 面板配置、校准 |
| 音频 | 3.2MB | - | 策略、配置 |
| 传感器 | 288KB | - | 传感器配置 |
| 温控 | 112KB | - | 场景温控配置 |
| 触控 | 232KB | - | ST FTS 固件 |
| 供应商属性 | 28KB | - | 设备身份标识 |
| ODM | 2MB | - | ODM 配置 |
| mi_ext | 268KB | - | 小米扩展层 |
| **总计** | **~881MB** | **~1200+** | |

## 🔧 关键配置

### 分区布局

| 分区 | 大小 | 文件系统 | 说明 |
|------|------|----------|------|
| boot | 192MB | - | 内核 + ramdisk |
| vendor_boot | 96MB | - | 供应商 ramdisk |
| dtbo | 23MB | - | 设备树覆盖 |
| super | 8.5GB | - | 动态分区容器 |
| ├─ system | 909MB | erofs | AOSP 17 系统 |
| ├─ vendor | 1.6GB | erofs | 12S Pro 供应商 |
| ├─ product | 3.4GB | erofs | 产品定制 |
| ├─ system_ext | 869MB | erofs | 系统扩展 |
| ├─ odm | 1MB | erofs | ODM 定制 |
| ├─ vendor_dlkm | 28MB | erofs | 供应商内核模块 |
| └─ mi_ext | 132KB | erofs | 小米扩展 |
| userdata | 105GB | f2fs | 用户数据 |

### 硬件特性

**相机系统：**
- 主摄：50MP Sony IMX707（广角）
- 超广角：48MP Samsung S5KJN1
- 长焦：48MP Samsung S5KJN1（5倍光学变焦）
- 前摄：32MP OmniVision OV32B40

**显示：**
- 6.73" LTPO AMOLED
- 3200x1440 分辨率
- 120Hz 刷新率
- HDR10+ 支持

**传感器：**
- 加速度计（LSM6DSO）
- 陀螺仪（LSM6DSO）
- 磁力计（AK0991X）
- 接近传感器（TMD3719）
- 环境光传感器（TCS3408）
- 气压计（LPS22HB）

**连接性：**
- 5G（Sub-6GHz + mmWave）
- Wi-Fi 6E
- 蓝牙 5.2
- NFC
- 红外遥控

## 🚀 构建步骤

### 1. 初始化环境

```bash
cd /Users/francisliu/Documents/个人新企划/Xiaomi_AI-OS
source build/envsetup.sh
```

### 2. 选择目标

```bash
lunch aosp_unicorn-trunk_staging-userdebug
```

### 3. 构建系统侧

```bash
m systemimage system_extimage productimage
```

> 完整 AOSP 构建需要 >100GB 磁盘，本机不可行；只构建 system / system_ext /
> product 三个系统侧镜像即可。super.img 由 `assemble-super.sh` 组装。

### 4. 组装 super.img

```bash
device/xiaomi/unicorn/assemble-super.sh    # 需要 m lpmake
```

### 5. 刷入设备

```bash
adb reboot bootloader
device/xiaomi/unicorn/flash-all.sh -w      # -w 首次刷机/换加密时擦 userdata/metadata
```

## ⚠️ 已知限制

### 1. 无供应商兼容层（根本约束）
- **问题**: Android 12 的 vendor 分区无法被纯 AOSP 17 系统驱动（上游已移除
  VNDK / vendor-HAL 兼容支持）。HAL 可能无法在 AOSP framework 上启动。
- **状态**: 无法仅靠配置解决；这是本移植的根本限制。已把 vendor/odm/
  vendor_dlkm/mi_ext 完整保留为预编译 EROFS 镜像，最大限度复用原 HAL。

### 2. 内核版本
- **问题**: 12S Pro 使用 5.10.236-android12-9，AOSP 17 默认期望 6.x
- **缓解**: 使用移植包内的预编译 boot 镜像（`TARGET_NO_KERNEL := true`）

### 3. SELinux 策略
- **说明**: 设备侧策略来自预编译 vendor 镜像内置的 sepolicy；本设备树**不**
  编译任何新策略，故 `sepolicy/` 目录有意省略（避免未定义类型导致编译失败）

### 4. 磁盘空间
- **问题**: 完整 AOSP 构建需要 >100GB，本机不可行
- **缓解**: 只构建 system/system_ext/product，vendor 侧用预编译镜像

### 5. Android 12 系统语义
- **说明**: AOSP 17 框架行为与 vendor 原配的 HyperOS 系统有差异，可能导致
  部分功能异常

## 🔍 验证检查

### 设备属性

```bash
# 检查设备代号
adb shell getprop ro.product.device
# 预期: unicorn

# 检查型号
adb shell getprop ro.product.model
# 预期: Xiaomi 12S Pro

# 检查内核
adb shell uname -a
# 预期: Linux version 5.10.236-android12-9
```

### HAL 检查

```bash
# 检查相机 HAL
adb shell lshal | grep camera

# 检查传感器 HAL
adb shell lshal | grep sensors

# 检查显示 HAL
adb shell lshal | grep display
```

## 🐛 故障排除

### 启动问题
1. **内核崩溃**: 检查 boot 镜像是否为移植包内 `boot_official.img`
2. **HAL 崩溃**: 通常是 AOSP 17 framework 与 Android 12 vendor 不兼容导致
   （见"已知限制"第 1 条），可刷回移植包原 super 验证
3. **vbmeta 验证失败**: 确认 BL 已解锁且 flash 时带 `--disable-verification`

## 📚 参考资料

- [小米 12S Pro 规格](https://www.mi.com/global/xiaomi-12s-pro)
- [骁龙 8+ Gen 1](https://www.qualcomm.com/products/mobile/snapdragon/8-plus-gen-1)
- [AOSP 设备配置](https://source.android.com/docs/setup/develop/new-device)

## 📄 许可证

```
Copyright (C) 2024 The LineageOS Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## 🙏 致谢

- **HyperOS 移植**: X-MiPort 团队的原始适配层
- **AOSP**: Android 开源项目
- **LineageOS**: 设备树结构参考

---

**移植完成日期**: 2026-11-12  
**移植方法**: system 侧 AOSP 构建 + vendor 侧预编译 EROFS 镜像保留（解锁 BL）  
**设备树**: `device/xiaomi/unicorn/` + `vendor/xiaomi/unicorn/`
