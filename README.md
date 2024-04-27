# Debian for toys

A (personal) set of scripts to build bootable Debian images for various architectures and development boards (or "toys", that's how we call them).

## Supported toys

* [RISC-V](riscv64/README.md)
  * QEMU (riscv64)
  * [SiFive HiFive Unleashed](https://www.sifive.com/boards/hifive-unleashed)
  * [StarFive VisionFive 2](https://doc-en.rvspace.org/Doc_Center/visionfive_2.html)

* POWER
  * [QEMU (ppc64le)](ppc64el/qemu/README.md)

More toys will be added as I acquire them and get them up and running (or migrate older scripts to this repository).

## !!! BIG FAT WARNING !!!

Scripts below do use sudo quite a lot. *IF THERE"S A BUG, IT MAY WIPE OUT
YOUR SYSTEM*. *DO NOT RUN THESE SCRIPTS WITHOUT READING THEM CAREFULLY FIRST*.

They're provided for convenience. Use at your own risk.

## Setting up host environment

**Disclaimer:** following recipe is (semi-regularly) tested on Debian Testing (Trixie at the time of writing). Debian 12 (Bookworm) is known to work too. If you have Debian 11 (Bullseye) or some other Debian-based distro, e.g, Ubuntu, this recipe may or may not work!

 1) Install required tools (QEMU, mmdebstrap and so on):

    ```
    sudo apt-get install mmdebstrap qemu-user-static qemu-system-misc binfmt-support debian-ports-archive-keyring rsync device-tree-compiler genimage genext2fs dosfstools guestfish guestfs-tools
    ```
 2) Install build tools for each architecture you want to build image for:

    ```
    crossbuild-essential-riscv64 crossbuild-essential-ppc64el
    ```

## Building bootable images

For each architecture and "board" you may find following scripts:

* `<arch>/<board>/mk-fs.sh <image>` to build a root filesystem. `<image>` can
  be either:

    * an empty directory
    * raw filesystem image containing ext4 file system
    * raw or `.qcow2` disk image containing a partition table and one exatly one ext4-formatted partition. Note, that when using `.qcow2` images, filesystem creation process is really slow.

* `<arch>/<board>/mk-os.sh` to build a linux kernel suitable for the board

* `<arch>/<board>/mk-ub.sh` to build U-Boot bootloader suitable for the board

* `<arch>/<board>/mk-im.sh` to build a complete disk / SD-card image to use with
  the board. `mk-im.sh` calls above scripts as needed to build bootloader, kernel
  and filesystem and package all that into a single file.


## Other Notes & Comments

* Connecting to serial console over FTDI:

  ```
  sudo screen /dev/ttyUSB0 115200
  ```

* Write SD card image to the SD card:

  ```
  pv images/sdcard.img | sudo dd of=/dev/mmcblk0 bs=32M oflag=sync
  ```

* Create `.tar.gz` of root filesystem from disk image:

  ```
  guestfish -a sdcard.img \
      run \
    : mount /dev/sda4 / \
    : tar-out / rootfs.tgz compress:gzip numericowner:true xattrs:true acls:true
  ```

  Replace `/dev/sda4` as needed.


* Sometimes it happened to me that `/var/lib/dpkg/available` disappeared. This prevents `dpkg` / `apt` from removing packages. Following command fixed this for me:

  ```
  sudo dpkg --clear-avail && sudo apt-get update
  ```

## License

This code is licensed under MIT license. See `LICENSE.txt`.
