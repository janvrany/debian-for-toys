#!/bin/bash
#
# Add support to act as a Jenking build node
#
#

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_JENKINS_UID:=500}
: ${CONFIG_JENKINS_GID:=500}
: ${CONFIG_JENKINS_PUBKEY:=path-to-jenkins-master-ssh-pubkey}

echo "Creating user jenkins..."
sudo chroot "${ROOT}" groupadd --gid "$CONFIG_JENKINS_UID" --system jenkins
sudo chroot "${ROOT}" useradd  --uid "$CONFIG_JENKINS_UID" --gid "$CONFIG_JENKINS_GID" --system --create-home --home-dir /var/lib/jenkins jenkins
echo "AllowUsers jenkins" | sudo tee "$ROOT/etc/ssh/sshd_config.d/jenkins.conf"

if [ -f "$CONFIG_JENKINS_PUBKEY" ]; then
	echo "Installing public key..."
	sudo mkdir -p                 "${ROOT}/var/lib/jenkins/.ssh"
	sudo cp "$CONFIG_JENKINS_PUBKEY" "${ROOT}/var/lib/jenkins/.ssh/authorized_keys"
	sudo chown -R "$JENKINS_UID" "${ROOT}/var/lib/jenkins/.ssh"
	sudo chmod -R go-rwx         "${ROOT}/var/lib/jenkins/.ssh"
	sudo chmod -R u=rw           "${ROOT}/var/lib/jenkins/.ssh"
	sudo chmod    u=rwx          "${ROOT}/var/lib/jenkins/.ssh"
fi

echo "Installing JDK"
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    default-jdk-headless

sudo chroot "${ROOT}" /usr/bin/apt-get clean