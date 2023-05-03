#!/bin/bash
#
# Bootstrap the debian
#

set -xe

CONFIG_BUILD_HOOK_DIR="$(dirname $0)/mk-fs-hooks"
CONFIG_BUILD_TMP_DIR="$(dirname $(readlink $0 || echo $0))/build/tmp"

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../3rdparty/toolbox/build.sh"
