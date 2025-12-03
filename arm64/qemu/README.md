Partition disk image

```
guestfish -a arm64.img run \
	: part-init /dev/sda gpt \
	\
	: part-add /dev/sda p 2048 65535 \
	: part-set-gpt-type /dev/sda 1 C12A7328-F81F-11D2-BA4B-00A0C93EC93B \
	: part-set-name /dev/sda 1 "EFI"
	: mkfs vfat /dev/sda1 \
    \
	: part-add /dev/sda p 65536 -2048 \
    : mkfs ext4 /dev/sda2 \
    : part-set-name /dev/sda 2 "Linux"
```