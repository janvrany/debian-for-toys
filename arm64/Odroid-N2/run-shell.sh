#!/bin/bash
#
# Run interactive shell "in the image" using systemd-nspawn
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/functions.sh"
config "$(dirname $0)/config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/config-local.sh"

#
# Config variables
#
: ${CONFIG_DEBIAN_ARCH:=amd64}
: ${CONFIG_DEBIAN_RELEASE:=trixie}
: ${CONFIG_HOSTNAME:="${CONFIG_DEBIAN_RELEASE}-${CONFIG_DEBIAN_ARCH}"}
: ${CONFIG_BUILD_TMP_DIR:="$(dirname $0)/tmp"}

test -z "${CONFIG_RUN_SHELL_BIND_USER+x}" || warn "CONFIG_RUN_SHELL_BIND_USER is obsolete, IGNORING. Use -u USER option!"
test -z "${CONFIG_RUN_SHELL_BIND_HOME+x}" || warn "CONFIG_RUN_SHELL_BIND_HOME is obsolete, IGNORING. Use -h option!"

#
#
#
systemd_nspawn_opts=()


usage() { echo "Usage: $0 [-u USER|-h] [-x] [-t] IMAGE [COMMAND]" 1>&2; exit 1; }

while getopts ":u:hxt" o; do
    case "${o}" in
        u)
            systemd_nspawn_opts+=("-u" "${OPTARG}")
            ;;
        h)
            systemd_nspawn_opts+=("--bind=${HOME}")
            ;;
        x)
            systemd_nspawn_opts+=("-x")
            ;;
        t)
            systemd_nspawn_opts+=("--bind" "$(realpath $CONFIG_BUILD_TMP_DIR):/tmp")
            ;;
    esac
done
shift $((OPTIND-1))


#
# Mount and umount the root
#
if [ -z "$1" ]; then
    usage
    exit 1
else
    ROOT_IMAGE=$1
    shift
fi

if [ -d "$ROOT_IMAGE" ]; then
    systemd_nspawn_opts+=("--directory=$ROOT_IMAGE")
else
    systemd_nspawn_opts+=("--image=$ROOT_IMAGE")
fi

systemd_nspawn_opts+=("--hostname" "$CONFIG_HOSTNAME")
systemd_nspawn_opts+=("--bind-ro" "/etc/resolv.conf:/etc/resolv.conf")

if [ -z "$1" ]; then
    # Run interactive shell
    sudo systemd-nspawn "${systemd_nspawn_opts[@]}"
else
    # Run command inside the container
    sudo systemd-nspawn "${systemd_nspawn_opts[@]}" \
                        -a "$@"
fi
