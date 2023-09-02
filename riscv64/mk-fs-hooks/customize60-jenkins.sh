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
: ${CONFIG_JENKINS_WORKSPACE_NFS:=}

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

if [ ! -z "$CONFIG_JENKINS_WORKSPACE_NFS" ]; then
	sudo mkdir -p "${ROOT}/var/lib/jenkins/workspace"
echo "
[Unit]
Description=Mount Jenkins workspace over NFS
After=network.target
Before=remote-fs.target

[Mount]
What=$CONFIG_JENKINS_WORKSPACE_NFS
Where=/var/lib/jenkins/workspace
Type=nfs4
Options=rw,async,noatime,nodiratime,vers=4.2,ac,rsize=4096,wsize=4096

[Install]
WantedBy=multi-user.target
" | sudo tee "$ROOT/etc/systemd/system/var-lib-jenkins-workspace.mount"
chroot "${ROOT}" systemctl enable var-lib-jenkins-workspace.mount

echo "
#
# /var/var/lib/jenkins/workspace is auto-mounted using 'var-lib-jenkins-workspace.mount' unit
#
# To modify, disable or enable mount of /var/var/lib/jenkins/workspace use
#
#     systemctl edit var-lib-jenkins-workspace.mount
#     systemctl disable var-lib-jenkins-workspace.mount
#     systemctl enable var-lib-jenkins-workspace.mount
#
#

" | sudo tee -a "$ROOT/etc/fstab"
fi
