#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release

# Print versions of distro and installed packages
rpm -q bats container-selinux passt passt-selinux podman podman-tests policycoreutils selinux-policy

loginctl enable-linger "$ROOTLESS_USER"

# Run podman system tests
su - "$ROOTLESS_USER" -c "bats /usr/share/podman/test/system/410-selinux.bats"
su - "$ROOTLESS_USER" -c "bats /usr/share/podman/test/system/500-networking.bats"
su - "$ROOTLESS_USER" -c "bats /usr/share/podman/test/system/505-networking-pasta.bats"
