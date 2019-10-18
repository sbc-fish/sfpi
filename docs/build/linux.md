# Linux 内核编译

## 下载 Linux 源码和应用 Patch

我们在 [sbc-fish/sfpi:/linux](https://github.com/sbc-fish/sfpi/tree/master/linux) 维护了对 Linux 主线内核的 Patch 。它提供了咸鱼派设备的 DTS、默认的 `.config` 和其它一些小的更改。目前已经支持的内核版本见以上链接，其它内核版本可根据最接近的内核版本的 Patch 进行更改。

下载 Linux 内核源码，以 4.19.32 为例：

```shell
$ wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.19.32.tar.xz
$ tar xvf linux-4.19.32.tar.xz
$ cd linux-4.19.32
```

应用我们提供的 Patch ：

```shell
$ curl https://raw.githubusercontent.com/sbc-fish/sfpi/master/linux/4.19.32/sfpi-linux-4.19.32.patch | patch -p1
patching file arch/arm/boot/dts/Makefile
patching file arch/arm/boot/dts/sun8i-v3s-saltedfishpi.dts
patching file arch/arm/boot/dts/sun8i-v3s.dtsi
patching file arch/arm/configs/saltedfishpi_defconfig
```

## 获取交叉编译工具链

您如果已经阅读过 [编译和刷入 U-Boot]（https://sbc-fish.github.io/sfpi/uboot/）中的相关部分，可以跳过这一小节。

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

对于未列出的 Linux 发行版，您可以搜索一下它的源有没有交叉编译工具链，如果没有，也可以使用 [Linaro GCC](https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-eabi/)。

由于各发行版安装的交叉编译器前缀不同，如果安装的编译器是 arm-none-eabi-gcc ，那么我们之后用到的 CROSS_COMPILE 就是 arm-none-eabi- ，即去掉最后的 gcc 部分。其它常见的还有 arm-linux-gnueabihf- 和 arm-linux-gnueabi ，都可以。

## 生成并更改 Linux .config

### 采用我们提供的 .config

在刚才应用的 Patch 中，已经包含了一个已经测试的 .config ，输入如下命令：

```shell
$ make ARCH=arm CROSS_COMPILE=arm-none-eabi- saltedfishpi_defconfig
```

如果想要自己调整配置：

```shell
$ make ARCH=arm CROSS_COMPILE=arm-none-eabi- menuconfig
```

## 编译 Linux 内核

用如下命令编译 Linux 内核：

```shell
$ make ARCH=arm CROSS_COMPILE=arm-none-eabi- -j4
```

编译 Linux 的时长取决于您的机器的硬件设施，并根据 CPU 线程数调整 `-j` 参数。不妨在等待 Linux 编译的时候点杯咖啡。

编译好后，应该可以得到我们想要的 `arch/arm/boot/zImage` 和 `arch/arm/boot/dts/sun8i-v3s-saltedfishpi.dtb` 文件。

## 写入 TF 卡

将编译得到的 `arch/arm/boot/zImage` 和 `arch/arm/boot/dts/sun8i-v3s-saltedfishpi.dtb` 文件拷贝入 TF 卡的文件系统中。建议写入 FAT 或者 EXT 文件系统。

## 准备 rootfs

仅有内核并不够，我们还需要一个 rootfs 。常见的办法有 buildroot 和直接采用已有的发行版的镜像，这里以 ArchLinuxARM 为例，假设我们预期的 rootfs 分区已经挂载到了 `mnt` 处：

```shell
$ wget http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
$ bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C mnt
```

您如果采用的是 macOS 系统并且无法写入 EXT4 文件系统，可以先找到一台 Linux 机器，进行如下操作：

```shell
$ dd if=/dev/zero of=archlinuxarm.img bs=1M count=1024
$ mkfs.ext4 archlinuxarm.img
$ sudo mount -o loop archlinuxarm.img mnt
$ wget http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz
$ bsdtar -xpf ArchLinuxARM-armv7-latest.tar.gz -C mnt
$ sudo umount mnt
```

将得到的 `archlinuxarm.img` 复制到 macOS 系统下，再写入：

```shell
$ sudo dd if=archlinuxarm.img of=/dev/[disk] bs=65535
```

此处的 `[disk]` 可以用 `diskutil list` 找到相应的分区。为了性能更好，可以在设备名称前添加一个 `r` ，如 `/dev/rdisk4s2` 。

如果您在 macOS 上安装了 e2fsprogs （`brew install e2fsprogs`），可以把文件系统扩大成分区的完整大小：

```shell
$ sudo /usr/local/opt/e2fsprogs/sbin/resize2fs -p /dev/[disk]
```

这里的 `[disk]` 意义同上。


## 配置 U-Boot 启动选项

在[编译和刷入 U-Boot](https://sbc-fish.github.io/sfpi/uboot/)中，您应该已经可以进入到 U-Boot 的界面了。首先需要找到我们刚才构建得到的内核和 `.dtb` 文件。查看 TF 卡的分区表：

```shell
=> part list mmc 0

Partition Map for MMC device 0  --   Partition Type: DOS

Part    Start Sector    Num Sectors     UUID            Type
  1     8192            85045           68db6199-01     0c
  2     94208           30453760        68db6199-02     83
=>
```

此处可以看到 TF 卡上的分区情况。这里的例子是，一个 FAT 分区保存内核和 `.dtb` 文件，另一个 EXT4 分区存放着 rootfs 。输入以下命令可以确认一下内核存放的地方：

```shell
=> fatls mmc 0:1 # 浏览分区 1 （FAT 文件系统）上的文件
=> ext4ls mmc 0:2 # 浏览分区 2 （EXT4 文件系统）上的文件
```

在本教程中，所需的文件 `zImage` 和 `sun8i-v3s-saltedfishpi.dtb` 放在了第一个分区（FAT 文件系统）中。输入如下命令把内核和 `.dtb` 文件加载到内存中：

```shell
=> fatload mmc 0:1 0x41000000 zImage
=> fatload mmc 0:1 0x41800000 sun8i-v3s-saltedfishpi.dtb
```

如果是 EXT4 文件系统，可以采用 `ext2load` 或者 `ext4load` 代替上面的 `fatload` 命令。现在开始启动入内核：

```shell
=> setenv bootargs console=ttyS0,115200
=> bootz 0x41000000 - 0x41800000
```

此时应该可以看到 Linux 内核成功启动，但因为找不到 rootfs，所以未能完成启动。在上面的例子中，rootfs 位于 TF 卡的第二个分区，于是可以更改启动参数并进入内核：

```shell
=> fatload mmc 0:1 0x41000000 zImage
=> fatload mmc 0:1 0x41800000 sun8i-v3s-saltedfishpi.dtb
=> setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait
=> bootz 0x41000000 - 0x41800000
```

需要注意的是，这里的 `rootwait` 必须要添加，另外 `/dev/mmcblk0p2` 代表了 TF 卡上的第二个分区，在刚才没有指定 rootfs 的时候，内核会输出如下信息：

```
[    2.252872] Please append a correct "root=" boot option; here are the available partitions:
[    2.261315] b300        15273984 mmcblk0
[    2.261320]  driver: mmcblk
[    2.268156]   b301           42522 mmcblk0p1 68db6199-01
[    2.268159]
[    2.274971]   b302        15226880 mmcblk0p2 68db6199-02
[    2.274974]
```

您可以根据在这里显示出来的信息找到并把 `mmcblk0p2` 改成相应的 rootfs 。

如果想要保存启动命令，使得之后都可以自动启动，输入以下指令：

```
=> setenv bootcmd 'fatload mmc 0:1 0x41000000 zImage;fatload mmc 0:1 0x41800000 sun8i-v3s-saltedfishpi.dtb; setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait; bootz 0x41000000 - 0x41800000'
=> saveenv
```

此后每次上电之后 U-Boot 就会自动启动进入 Linux 了。也可以手动输入 `boot` 进入 Linux 。
