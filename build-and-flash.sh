#!/bin/bash
CHIP_TOOLS_PATH="$PWD/CHIP-SDK/CHIP-tools"
UBOOT_PATH="$PWD/CHIP-SDK/CHIP-buildroot/output/build/uboot-nextthing_2016.01_next"
ROOTFS_PATH="$PWD/rootfs.tar"

cd $CHIP_TOOLS_PATH
rm -rf new-image
sudo ./chip-create-nand-images.sh $UBOOT_PATH $ROOTFS_PATH new-image
sudo chown -R $USER:$USER ./new-image
./chip-flash-nand-images.sh new-image/
