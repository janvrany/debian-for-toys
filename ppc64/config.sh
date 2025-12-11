CONFIG_DEBIAN_RELEASE=sid
CONFIG_DEBIAN_SOURCES="deb https://deb.debian.org/debian-ports sid main deb https://deb.debian.org/debian-ports unreleased main"

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../common/config.sh"
