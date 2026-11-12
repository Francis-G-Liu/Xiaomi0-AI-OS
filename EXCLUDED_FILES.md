# 未纳入 git 的文件

为保证仓库可推送到 GitHub，以下内容被排除（`.gitignore` + 手动过滤）。

## 1. 上游 AOSP 源码

本仓库只是项目层。完整的 1087 个 AOSP 仓库请用：

```bash
repo init -u https://github.com/Francis-G-Liu/Xiaomi0-AI-OS.git -b main -m manifest/default.xml
repo sync -c --no-tags -j8
```

## 2. 预编译镜像（体量大，建议放 GitHub Releases）

| 路径 | 大小 |
|---|---|
| `X-MiPort_Mi12SPro_OS4/images/super.img.zst` | 5.9 GB |
| `X-MiPort_Mi12SPro_OS4/images/modem.img` | 305 MB |
| `X-MiPort_Mi12SPro_OS4/images/vm-bootsys.img` | 270 MB |
| `X-MiPort_Mi12SPro_OS4/images/`（其余） | — |
| `vendor/xiaomi/unicorn/prebuilt_images/vendor_a.img` | 1.7 GB |
| `vendor/xiaomi/unicorn/prebuilt_images/`（其余） | — |
| `device/xiaomi/unicorn/prebuilt/boot/boot_official.img` | 192 MiB |
| `device/xiaomi/unicorn/prebuilt/boot/recovery.img` | 100 MiB |
| `device/xiaomi/unicorn/prebuilt/boot/vendor_boot.img` | 96 MiB |
| `device/xiaomi/unicorn/prebuilt/dtbo/dtbo.img` | 23 MiB |

这些镜像不参与 AOSP 编译，只用于刷机。需要时从原始移植包或设备固件重新获取，
或发布在本仓库的 Releases 页面。

## 3. 超过 GitHub 单文件限制（100 MiB）的 blob

| 路径 | 大小 |
|---|---|
| `vendor/xiaomi/unicorn/proprietary/vendor/lib64/libxmi_high_dynamic_range_cdsp.so` | 150 MiB |

如需完整 vendor blob，可在本地用 `device/xiaomi/unicorn/extract-files.sh` 从设备固件重新提取。

## 4. 构建产物

`out/`：本地编译产物，不纳入版本管理。
