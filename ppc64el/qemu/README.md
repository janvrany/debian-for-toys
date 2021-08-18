# Debian on PPC64le QEMU

## Setting up host environment

**Disclaimer:** following recipe is (semi-regularly) tested on Debian Testing (Bookworm at the time of writing). Debian 11 (Bullseye) If you have some other Debian-based distro, e.g, Ubuntu, this recipe may or may not work!

* Install QEMU, `mmdebstrap` and PPC64le build toolchain:
  ```
  sudo apt-get install mmdebstrap qemu-user-static qemu-system-misc binfmt-support crossbuild-essential-ppc64el
  ```

## Checking out source code

```
git clone https://github.com/janvrany/debian-for-toys
git -C debian-for-toys submodule update --init common/linux
```

## !!! BIG FAT WARNING !!!

Scripts below do use sudo quite a lot. *IF THERE"S A BUG, IT MAY WIPE OUT
YOUR SYSTEM*. *DO NOT RUN THESE SCRIPTS WITHOUT READING THEM CAREFULLY FIRST*.

They're provided for convenience. Use at your own risk.


## Creating PPC64le Debian Image

1. Build linux kernel image:

   ```
   cd ppc64le/qemu
   ./mk-os.mk
   ```

2. Create a file containing Debian root filesystem. This is optional, you may use
   directly a device (say `/dev/mmcblk0p2`) or ZFS zvolume (`/dev/zvol/...`). You
   will need at least 4GB of space but for development, use 8G (or more). C++
   object files with full debug info can be pretty big.

   ```
   truncate -s 8G debian.img
   /sbin/mkfs.ext4 debian.img
   ```

   Then install full Debian system into it:

   ```
   ./mk-fs.sh debian.img
   ```

## Running

    ```
    ./qemu.sh debian.img
    ```

## Acknowledgement

Thanks to @shingarov for support and hints.

