#/bin/bash

set -e

env

DEBIAN_RELEASE=sid
DEBIAN_SOURCES="deb http://deb.debian.org/debian-ports sid main"

. $(dirname $0)/../../common/mk-fs.sh

