# 咸鱼派编译和刷入 U-Boot 教程

## 从源代码编译 U-Boot

### 获取 U-Boot

在网上获取 U-Boot 的源代码。以 Github 为例，把 [u-boot/u-boot](https://github.com/u-boot/u-boot) 仓库克隆下来：

```shell
$ git clone git@github.com:u-boot/u-boot.git
```

如果想要一个稳定版本的 U-Boot ，你可以 checkout 一个 tag，以 v2018.11-rc3 为例：

```shell
$ git checkout v2018.11-rc3
```


或者直接下载指定版本的 U-Boot 源码，以 v2018.11-rc3 为例：

```shell
$ wget https://github.com/u-boot/u-boot/archive/v2018.11-rc3.tar.gz
$ tar xvf v2018.11-rc3.tar.gz
```

### 获取交叉编译工具链

您如果是 Archlinux 用户，可以直接安装 [arm-none-eabi-gcc](https://www.archlinux.org/packages/community/x86_64/arm-none-eabi-gcc/) ：

```shell
$ sudo pacman -Sy arm-none-eabi-gcc
```

您如果是 Debian 用户，可以安装  [gcc-arm-linux-gnueabihf](https://packages.debian.org/buster/gcc-arm-linux-gnueabihf) ：

```shell
$ sudo apt install gcc-arm-linux-gnueabihf
```

您如果是 Ubuntu 用户，可以安装 [gcc-arm-linux-gnueabihf](https://packages.ubuntu.com/bionic/gcc-arm-linux-gnueabihf)

```shell
$ sudo apt-get install gcc-arm-linux-gnueabihf
```

您如果是 Fedora 用户，可以安装 [arm-none-eabi-gcc-cs](https://rpmfind.net/linux/rpm2html/search.php?query=arm-none-eabi-gcc)

```shell
$ sudo dnf install arm-none-eabi-gcc-cs
```

对于未列出的 Linux 发型版，您可以搜索一下它的源有没有交叉编译工具链，如果没有，也可以使用 [Linaro GCC](https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-eabi/)。

由于各发型版安装的交叉编译器前缀不同，如果安装的编译器是 arm-none-eabi-gcc ，那么我们之后用到的 CROSS_COMPILE 就是 arm-none-eabi- ，即去掉最后的 gcc 部分。其它常见的还有 arm-linux-gnueabihf- 和 arm-linux-gnueabi ，都可以。

### 配置 U-Boot

#### 采用我们提供的 .config

我们提供的已经测试过的 U-Boot 的 .config 文件已经存放在 [sbc-fish/sfpi 的 u-boot](https://github.com/sbc-fish/sfpi/tree/master/u-boot) 目录下。这里的 .config 都是可以直接复制到 U-Boot 根目录中使用的。

以 U-Boot v2018.11-rc3 为例，进入到 U-Boot 目录，下载 .config ：

```shell
$ wget https://raw.githubusercontent.com/sbc-fish/sfpi/master/u-boot/v2018.11-rc3/.config
```

如果我们没有提供相应版本的 .config ，可以找一个版本较近的 .config 下载下来用，如果有部分配置需要更改，在后续编译的时候会有相应的提示，一般用默认参数就可以了。

如果想要自己调整配置：

```shell
$ make ARCH=arm CROSS_COMPILE=arm-none-eabi- menuconfig
```

其中 CROSS_COMPILE 是您所安装的交叉编译工具链的前缀。如果您使用我们提供的 .config ，应该不需要做更改。

## 编译 U-Boot

然后开始编译：

```shell
$ make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j24
```

其中 `-j24` 根据您的机器的 CPU 进行调整。此时应该得到一个 `u-boot-sunxi-with-spl.bin` 的文件，在当前目录下。


### 刷入 U-Boot

#### 分区

建议向 TF 卡写入 MBR 格式的分区表，并在第一个分区前预留一定的空间。如果我们在上一步编译的文件大小为几百 K ，一个可供参考的分区方案是：

```
Disk: /dev/disk4        geometry: 980/128/63 [7907328 sectors]
Offset: 0       Signature: 0xAA55
         Starting       Ending
 #: id  cyl  hd sec -  cyl  hd sec [     start -       size]
------------------------------------------------------------------------
 1: 0B 1023 254  63 - 1023 254  63 [      2048 -      20480] Win95 FAT-32
 2: 83 1023 254  63 - 1023 254  63 [     22528 -    7884800] Linux files*
 3: 00    0   0   0 -    0   0   0 [         0 -          0] unused
 4: 00    0   0   0 -    0   0   0 [         0 -          0] unused
```

第一个分区（FAT-32）从第 2048 个扇区开始，即在 1M （2048*512=1M） 的地方开始，这样给 U-Boot 预留出足够的空间。这个预留的空间大小，根据编译出来的 `u-boot-sunxi-with-spl.bin` 文件和 TF 卡容量自行调整。对于分区工具的使用，可以参考 [Partitioning - Archlinux Wiki](https://wiki.archlinux.org/index.php/Partitioning#Master_Boot_Record) 、 [fdisk - Archlinux Wiki](https://wiki.archlinux.org/index.php/Fdisk) 或 [fdisk Manpages](https://ss64.com/osx/fdisk.html) 。

#### 使用 DD 刷入 U-Boot

把 `u-boot-sunxi-with-spl.bin` 写入到 TF 卡的 8192 偏移处即可，命令如下：

```
$ sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/disk4 bs=1024 seek=8
```

如果您是 macOS 用户，可以使用我们编写的 [flash_uboot_macOS.sh](https://raw.githubusercontent.com/sbc-fish/sfpi/master/scripts/flash_uboot_macOS.sh) 。

## 启动

### 连接串口

把 TF 卡插入到咸鱼派中，连接 microUSB 到电脑中，应该会看到一个 USB to Serial 设备。各平台的驱动可以在[沁恒官网下载](http://www.wch.cn/downloads/CH341SER_ZIP.html)得到。在 Windows 下，可以采用串口助手等工具，在 Linux 和 macOS 下，可以用如下命令：

```
$ screen [tty] 115200
```

查看串口。对于 macOS ，此处的 tty 应为 /dev/tty.wchusbserial* 的格式。

按下板上的上电按钮，如果配置成功，应该可以成功看到 U-Boot 的启动如下：

```
U-Boot SPL 2018.11-rc3 (Nov 09 2018 - 11:55:32 +0800)
DRAM: 64 MiB
Trying to boot from MMC1


U-Boot 2018.11-rc3 (Nov 09 2018 - 11:55:32 +0800) Allwinner Technology

CPU:   Allwinner V3s (SUN8I 1681)
Model: Lichee Pi Zero
DRAM:  64 MiB
MMC:   SUNXI SD/MMC: 0
Loading Environment from FAT... OK
In:    serial@01c28000
Out:   serial@01c28000
Err:   serial@01c28000
Net:   No ethernet found.
starting USB...
No controllers found
Hit any key to stop autoboot:  0
=>
```

至此，我们就可以进行下一步的 Linux 内核编译过程了。