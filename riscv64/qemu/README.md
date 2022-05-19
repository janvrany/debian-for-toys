# Debian on RISC-V 64 QEMU

## Setting up host environment

**Disclaimer:** following recipe is (semi-regularly) tested on Debian Testing (Bookworm at the time of writing). If you have Debian 11 (Bullseye) or some other Debian-based distro, e.g, Ubuntu, this recipe may
or may not work!

* Compile and install RISC-V GNU toolchain. See [RISC-V GNU toolchain README][15] on how to do so - in short following should do
  it, but ensure that the `--prefix` location is writable by the user you run `make linux` as

      sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git
      git clone https://github.com/riscv/riscv-gnu-toolchain
      cd riscv-gnu-toolchain
      git submodule update --init --recursive
      ./configure --prefix=/opt/riscv --enable-linux
      make linux

  This toolchain is needed to compile the kernel. As of 2020-07-27, the Debian-provided RISC-V cross toolchain is not able to link Linux kernel and fails with link error.


* Install QEMU, `mmdebstrap` and RISC-V 64 build toolchain:
  ```
  sudo apt-get install mmdebstrap qemu-user-static qemu-system-misc binfmt-support debian-ports-archive-keyring gcc-riscv64-linux-gnu rsync device-tree-compiler
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


## Creating RISC-V 64 Debian Image

1. Build linux kernel image:

   ```
   cd riscv64/qemu
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

## Other comments

### How to fix missing `/var/lib/dpkg/available`

Sometimes it happened to me that `/var/lib/dpkg/available` disappeared.
This prevents `dpkg` / `apt` from removing packages. Following command
fixed this for me:

```
sudo dpkg --clear-avail && sudo apt-get update
```

## References
* [https://wiki.debian.org/RISC-V][1]
* [https://github.com/jim-wilson/riscv-linux-native-gdb/blob/jimw-riscv-linux-gdb/README.md][2]
* [https://groups.google.com/a/groups.riscv.org/forum/#!msg/sw-dev/jTOOXRXyZoY/BibnmSTOAAAJ][3]
* [https://wiki.debian.org/InstallingDebianOn/SiFive/HiFiveUnleashed#Building_a_Kernel][4]
* [https://github.com/sifive/freedom-u-sdk/issues/44][6]
* [https://github.com/rwmjones/fedora-riscv-kernel][7]
* [https://github.com/andreas-schwab/linux][8]
* [https://forums.sifive.com/t/linux-4-20-on-hifive-unleashed/1955][9]
* [SiFive HiFive Unleashed Getting Started Guide][10]

[1]: https://wiki.debian.org/RISC-V
[2]: https://github.com/jim-wilson/riscv-linux-native-gdb/blob/jimw-riscv-linux-gdb/README.md
[3]: https://groups.google.com/a/groups.riscv.org/forum/#!msg/sw-dev/jTOOXRXyZoY/BibnmSTOAAAJ
[4]: https://wiki.debian.org/InstallingDebianOn/SiFive/HiFiveUnleashed#Building_a_Kernel
[5]: https://github.com/sifive/freedom-u-sdk/blob/a938cf74b958cee13bdd2f9c9945297f744a2109/Makefile#L228
[6]: https://github.com/sifive/freedom-u-sdk/issues/44
[7]: https://github.com/rwmjones/fedora-riscv-kernel
[8]: https://github.com/andreas-schwab/linux
[9]: https://forums.sifive.com/t/linux-4-20-on-hifive-unleashed/1955
[10]: https://sifive.cdn.prismic.io/sifive%2Ffa3a584a-a02f-4fda-b758-a2def05f49f9_hifive-unleashed-getting-started-guide-v1p1.pdf
[11]: https://jenkins.io/
[12]: https://wiki.jenkins.io/display/JENKINS/SSH+Slaves+plugin
[13]: https://packages.debian.org/testing/all/debian-ports-archive-keyring/download
[14]: https://packages.debian.org/testing/debian-ports-archive-keyring
[15]: https://github.com/riscv/riscv-gnu-toolchain/blob/master/README.md

