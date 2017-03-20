#!/bin/bash
# Brief
# This script will create a bootable custom Linux image that can be flashed to
# a CHIP Pro using the command line utilities in CHIP-tools.

# Prerequisites:
#   *  You are inside the CHIP-SDK directory
#   *  CHIP-SDK/CHIP-buildroot is compiled and rootfs.tar is uncompressed ->
#      CHIP-SDK/CHIP-buildroot/buildroot-rootfs

# Usage:
# sh build-rootfs.sh multistrap.conf
#     Where multistrap.conf is the relative path to the multistrap config
#     file you want to build your CHIP Pro image according to.

HERE="$PWD"
MULTISTRAP_CONF_FILE="$HERE/$1"
ROOTFS_DIR="$HERE/rootfs"
SDK_PATH="$HERE/CHIP-SDK"
BUILDROOT_PATH="$SDK_PATH/CHIP-buildroot"

# This compiles CHIP-buildroot and decompresses the resulting rootfs
# into the CHIP-buildroot/buildroot-rootfs directory for later reference.
# Note: This can take a LONG time! Even on a powerful machine.
compile_chip_buildroot () {
  cd $BUILDROOT_PATH
  make chippro_defconfig
  make
  rm -rf build-rootfs
  mkdir build-rootfs
  tar -xf $BUILDROOT_PATH/output/images/rootfs.tar -C ./build-rootfs
}

# Copy over relevant kernel and kernel modules for the CHIP Pro board
# from the CHIP-buildroot rootfs
copy_boot_modules () {
  cp -r $BUILDROOT_PATH/buildroot-rootfs/boot/* $ROOTFS_DIR/boot/
  cp -r $BUILDROOT_PATH/buildroot-rootfs/lib/modules $ROOTFS_DIR/lib/
}

# Create a rootfs using multistrap and clean any old data
create_rootfs () {
  sudo rm -rf $HERE/rootfs.tar $ROOTFS_DIR
  multistrap -f $MULTISTRAP_CONF_FILE -d $ROOTFS_DIR
  copy_boot_modules
  sudo chown -R $USER:$USER $ROOTFS_DIR
}

# This makes sure that sudo does not through any uid/gid errors
fix_sudo () {
  for FILE in /usr/bin/sudo /usr/lib/sudo/sudoers.so /etc/sudoers /etc/sudoers.d /etc/sudoers.d/README /var/lib/sudo
  do
    chown root:root $FILE
    chmod 4755 $FILE
  done
}

# This provides our target rootfs's rc.local.
# Ensures the target machine's console is not littered with WiFi driver logs
# while we are trying to use it in interactive mode.
suppress_dmesg () {
  echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

dmesg -D
exit 0" > $ROOTFS_DIR/etc/rc.local
}

# Incidental configuration of the customized rootfs
# This will vary depending on your multistrap config specifics
configure_rootfs () {
  fix_sudo

  # Mount rootfs as an armhf chroot
  sudo cp /usr/bin/qemu-arm-static $ROOTFS_DIR/usr/bin

  # chroot into rootfs
  sudo LC_ALL=C LANGUAGE=C LANG=C chroot $ROOTFS_DIR
  #sudo mount -o bind /dev/ $ROOTFS_DIR/dev/
  sudo mount -t proc nodev /proc/

  # Configure & complete installation of packages
  dpkg --configure -a
  sudo chown root:root -R /bin /usr/bin /usr/sbin

  #apt-get remove openssh-client openssh-server --purge
  #apt-get autoremove
  #apt-get install openssh-client openssh-server

  # Fix DNS resolution
  echo "nameserver 127.0.0.1" > /etc/resolv.conf
  suppress_dmesg

  # Update password of root user
  passwd

  # Create new 'driblet' user
  # Note: do this as root
  adduser driblet
  passwd driblet
  usermod -aG sudo driblet

  sudo rm $ROOTFS_DIR/usr/bin/qemu-arm-static
}

# Bundle final target rootfs as a tar file
bundle_rootfs () {
  cd $ROOTFS_DIR
  tar -cvf $HERE/rootfs.tar .
}

if [ ! -d "$BUILDROOT_PATH/buildroot-rootfs" ] ; then
  compile_chip_buildroot
fi
create_rootfs
configure_rootfs
bundle_rootfs
