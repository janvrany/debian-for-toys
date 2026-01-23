#!/bin/bash
#
# Deploy image to libvirt instance
#
set -e

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/config-local.sh"

#
# Config variables
#
# none (so far)

#
# Process options
#
usage() { echo "Usage: $(basename $0) -d DOMAIN IMAGE" 1>&2; exit 1; }

while getopts ":d:" o; do
    case "${o}" in
        d)
            CONFIG_DEPLOY_DOMAIN=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${CONFIG_DEPLOY_DOMAIN}" ]; then
    usage
elif [ -z "$1" ]; then
    usage
elif [ -d "$1" ]; then
    error "Invalid root filesystem image (must be an image file): $1"
    exit 2
fi

tmp=$(realpath $(dirname $0))/tmp
mkdir -p $tmp

SRC_IMG=$1
DST_IMG="$tmp/$CONFIG_DEPLOY_DOMAIN.qcow2"

qemu-img convert \
    -f "$(qemu-img info $1 | grep 'file format' | cut -d ' ' -f 3)" \
    -O qcow2 -o extended_l2=on,cluster_size=128k \
    "$SRC_IMG" "$DST_IMG"

qemu-img resize \
    -f qcow2 \
    "$DST_IMG" 50G

guestfish -a "$DST_IMG" -- \
    run : \
    part-expand-gpt /dev/sda : \
    part-resize /dev/sda 2 -100 : \
    resize2fs /dev/sda2 : \
    mount /dev/sda2 / : \
    write /etc/hostname "$CONFIG_DEPLOY_DOMAIN" : \
    write /etc/systemd/system/tmp.mount "
[Unit]
Description=Mount /tmp
After=
Before=local-fs.target

[Mount]
Where=/tmp
What=tmpfs
Type=tmpfs
Options=

[Install]
WantedBy=multi-user.target
" : \
    ln-s /etc/systemd/system/home.mount \
        /etc/systemd/system/multi-user.target.wants/tmp.mount : \
    write /etc/systemd/system/home.mount "
[Unit]
Description=Mount /home
After=network.target
Before=remote-fs.target
ConditionHost=$CONFIG_DEPLOY_DOMAIN

[Mount]
Where=/home
What=triton.home.arpa:/tank/homes
Type=nfs4
Options=rw,async,noatime,nodiratime,vers=4.2,ac

[Install]
WantedBy=multi-user.target
" : \
    ln-s /etc/systemd/system/home.mount \
         /etc/systemd/system/multi-user.target.wants/home.mount : \
    write /etc/systemd/system/swap0.service "
[Unit]
Description=Create & enable swap file 0
ConditionMemory= <=4G

[Install]
WantedBy=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=\"F=/var/cache/swap0\"
ExecStart=/bin/bash -c \"fallocate -l 4G \$F && chmod 0600 \$F && mkswap \$F && swapon \$F\"
ExecStop=/bin/bash -c \"swapoff \$F && rm -f \$F\"
" : \
    ln-s /etc/systemd/system/swap0.service \
         /etc/systemd/system/multi-user.target.wants/swap0.service : \
    write /etc/systemd/system/swap1.service "
[Unit]
Description=Create & enable swap file 1
ConditionMemory= <=8G

[Install]
WantedBy=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=\"F=/var/cache/swap1\"
ExecStart=/bin/bash -c \"fallocate -l 4G \$F && chmod 0600 \$F && mkswap \$F && swapon \$F\"
ExecStop=/bin/bash -c \"swapoff \$F && rm -f \$F\"
" : \
    ln-s /etc/systemd/system/swap1.service \
         /etc/systemd/system/multi-user.target.wants/swap1.service : \
    write /etc/systemd/system/swap2.service "
[Unit]
Description=Create & enable swap file 2
ConditionMemory= <=12G

[Install]
WantedBy=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=\"F=/var/cache/swap2\"
ExecStart=/bin/bash -c \"fallocate -l 4G \$F && chmod 0600 \$F && mkswap \$F && swapon \$F\"
ExecStop=/bin/bash -c \"swapoff \$F && rm -f \$F\"
" : \
    ln-s /etc/systemd/system/swap2.service \
         /etc/systemd/system/multi-user.target.wants/swap.service : \
    umount-all

qemu-img snapshot -c "base" "$DST_IMG"
qemu-img info "$DST_IMG"

echo "
Image prepared, upload it as:

    scp $DST_IMG triton.home.arpa:/syst/guests

"
