# Xiaomi0-AI-OS

Xiaomi 12S Pro（codename: **unicorn**，型号 2206122SC）的 AOSP 17 移植层。

本仓库是**项目层**，不包含上游 AOSP 源码本身。上游代码按 `manifest/` 中的清单用 `repo sync` 拉取。

## 目标

- 基线：AOSP Android 17（`android-17.0.0_r1`，`trunk_staging`）
- 机型：Xiaomi 12S Pro / unicorn（SM8475 "taro"，arm64）
- 策略：**system 侧用 AOSP 17 编译**（system / system_ext / product），
  **vendor 侧沿用移植包里的预编译 EROFS 镜像**（vendor / odm / vendor_dlkm / mi_ext）。
  详见 [`device/xiaomi/unicorn/README.md`](device/xiaomi/unicorn/README.md) 与
  [`device/xiaomi/unicorn/PORTING_SUMMARY.md`](device/xiaomi/unicorn/PORTING_SUMMARY.md)。

## 仓库内容

```
manifest/                       AOSP android-17.0.0_r1 清单（USTC 镜像）
device/xiaomi/unicorn/          设备树、BoardConfig、HAL manifest、刷机/打包脚本
vendor/xiaomi/unicorn/          小米预编译厂商 blob（proprietary/）与构建配置
X-MiPort_Mi12SPro_OS4/          移植包：刷机工具、RootManager、META-INF
```

## 不包含的内容

为满足 GitHub 的单仓库与单文件限制（100 MiB），以下内容**未纳入 git**，详见
[`EXCLUDED_FILES.md`](EXCLUDED_FILES.md)：

- 上游 AOSP 源码（按 manifest 用 `repo sync` 获取）
- 预编译镜像：`X-MiPort_Mi12SPro_OS4/images/`、`vendor/xiaomi/unicorn/prebuilt_images/`、
  `device/xiaomi/unicorn/prebuilt/boot/*.img`
- 超过 100 MiB 的单个厂商 blob
- `out/` 构建产物

## 复现编译

> 需要 Linux（推荐 Ubuntu 22.04+）、约 250 GB 磁盘、32 GB 内存。macOS 可编译部分模块，
> 但完整系统包建议在 Linux 上完成。

```bash
# 1. 拉取上游 AOSP 17 + 本仓库作为 manifest
mkdir aosp-unicorn && cd aosp-unicorn
repo init -u https://github.com/Francis-G-Liu/Xiaomi0-AI-OS.git -b main -m manifest/default.xml
repo sync -c --no-tags -j8

# 2. 叠加本仓库的项目层（manifest 仓库已检出在 .repo/manifests/）
cp -R .repo/manifests/device .
cp -R .repo/manifests/vendor .
cp -R .repo/manifests/X-MiPort_Mi12SPro_OS4 .

# 3. 编译
source build/envsetup.sh
lunch aosp_unicorn-trunk_staging-userdebug
m -j"$(nproc)"
```

产物与打包/刷机脚本见 `device/xiaomi/unicorn/assemble-super.sh`、`flash-all.sh`。

## 关于在 GitHub 上编译

GitHub 托管的 `ubuntu-latest` runner 只有约 14 GB 临时磁盘和 16 GB 内存，**无法**完成
AOSP 全量编译。要真正在 GitHub 上出包，需要使用带大磁盘的 **self-hosted runner**
（建议 ≥ 300 GB SSD、≥ 32 GB RAM），再在 Actions 中执行上面的 `repo sync` + `m`。
本仓库暂未附带 CI 工作流。

## 许可

- 本仓库自有部分：Apache-2.0
- `vendor/xiaomi/` 内为小米设备固件中的预编译二进制，版权归原权利人，仅供个人移植使用。
