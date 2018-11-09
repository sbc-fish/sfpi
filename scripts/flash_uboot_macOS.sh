#!/bin/sh
set -x #echo on
diskutil unmountDisk $1
sudo dd if=u-boot-sunxi-with-spl.bin of=$1 bs=1024 seek=8
