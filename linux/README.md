# 咸鱼派 Linux Patches

这里是我们对主线内核进行的修改，以 Patch 的形式保存。

现在已包括的内核版本有：

- 4.19.1

## Patch 内容

- DTS 文件
- 默认的 `.config`
- 修改蓝牙驱动（RTL8723bs）

## 使用方法

### 下载 Linux 内核源码并应用 Patch

下载对应的 Linux 内核源码，以 4.19.1 为例：

```
$ wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.1.tar.xz
$ tar xvf linux-4.19.1.tar.xz
$ cd linux-4.19.1
```

应用我们提供的 Patch ：

```
$ curl https://raw.githubusercontent.com/sbc-fish/sfpi/master/linux/4.19.1/sfpi-linux-4.19.1.patch | patch -p1
patching file arch/arm/boot/dts/Makefile
patching file arch/arm/boot/dts/sun8i-v3s-saltedfishpi.dts
patching file arch/arm/boot/dts/sun8i-v3s.dtsi
patching file arch/arm/configs/saltedfishpi_defconfig
patching file drivers/bluetooth/Kconfig
patching file drivers/bluetooth/hci_h5.c
```