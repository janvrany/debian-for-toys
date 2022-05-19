#/bin/bash

set -e

. $(dirname $0)/../../common/functions.sh

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

if [[ -z $ARCH ]]; then
    ARCH=$(basename $(realpath $(dirname $0)/..))
fi
if [[ -z $DEBIAN_RELEASE ]]; then
    DEBIAN_RELEASE=testing
fi

if [[ -z $DEBIAN_SOURCES ]]; then
    DEBIAN_SOURCES="deb http://deb.debian.org/debian $DEBIAN_RELEASE main contrib"
fi

ensure_ROOT "$1"

# ensure_ROOT mount /proc, /sys, /dev/pts and /dev/shm in order to allow
# for easy chroot. However,`mmdebstrap` requires destination directory to
# be empty so umount them (if mounted)
unbind_filesystems


# mkfs.ext3 creates lost+found directory, but `mmdebstrap` requires
# destination directory to be empty. So, remove `lost+found` is it exists
# and if it's empty...
if [ -d "${ROOT}/lost+found" ]; then
    if [ -z "$(ls -A ${ROOT}/lost+found)" ]; then
        sudo rmdir "${ROOT}/lost+found"
    fi
fi

# ...and check then check again.
if [ ! -z "$(ls -A ${ROOT})" ]; then
    echo "Root directory is not empty: ${ROOT}"
    echo "Please remove all files an retry"
    exit 2
fi

# Setup hooks
common_hooks_dir=$(realpath $(dirname $0)/../../common/mk-fs-hooks)

if [ -d $(dirname $0)/../mk-fs-hooks ]; then
    arch_hooks_dir=$(realpath $(dirname $0)/../mk-fs-hooks)
    arch_hooks_arg="--hook-directory=$arch_hooks_dir"
fi
if [ -d $(dirname $0)/mk-fs-hooks ]; then
    board_hooks_dir=$(realpath $(dirname $0)/mk-fs-hooks)
    board_hooks_arg="--hook-directory=$board_hooks_dir"
fi

# Setup global apt cache
cache_apt=$(realpath $(dirname $0)/..)/cache/apt/archives
mkdir -p $cache_apt

# Bootstrap!
sudo \
mmdebstrap \
    --variant=minbase \
    --architectures=$ARCH --include="debian-ports-archive-keyring" \
    --skip=download/empty --skip=essential/unlink --skip=cleanup/apt \
    --setup="mkdir -p $(realpath $ROOT)/var/cache/apt/archives/" \
    --setup="sync-in $cache_apt /var/cache/apt/archives/" \
    --setup="ls $(realpath $ROOT)/var/cache/apt/archives/" \
    --hook-directory=$(realpath $(dirname $0)/../../common/mk-fs-hooks) \
    $arch_hooks_arg \
    $board_hooks_arg \
    $DEBIAN_RELEASE "$ROOT" \
    "$DEBIAN_SOURCES"

# Archive and cleanup downloaded packages
ls    $(realpath $ROOT)/var/cache/apt/archives/*.deb
cp -u $(realpath $ROOT)/var/cache/apt/archives/*.deb $cache_apt
rm -f $(realpath $ROOT)/var/cache/apt/archives/*.deb