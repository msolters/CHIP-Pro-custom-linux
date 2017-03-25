#!/bin/bash
# Brief
# Creates a final NAND image (directory ready-to-flash) from the /rootfs
# in the directory.

HERE="$PWD"
MULTISTRAP_CONF_FILE="$HERE/$1"
ROOTFS_DIR="$HERE/rootfs"

# rootfs/ -> ./rootfs.tar
bundle_rootfs () {
  # Make sure chroot is not mounted!
  bash mount-chroot.sh -u

  # Tar up rootfs
  cd $ROOTFS_DIR
  sudo tar -cf $HERE/rootfs.tar .
}

# rootfs.tar -> NAND image
build_rootfs () {
  cd $HERE
  sudo rm -rf $HERE/new-image
  sudo bash "$CHIP_TOOLS_PATH/chip-create-nand-images.sh" "$UBOOT_PATH" "$ROOTFS_DIR.tar" "$HERE/new-image"
  sudo chown -R $USER:$USER $HERE/new-image
}

bundle_rootfs
build_rootfs
