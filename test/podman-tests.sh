#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release

if [[ "$(id -u)" -ne 0 ]];then
    echo "Please run as superuser"
    exit 1
fi

# Print versions of distro and installed packages
rpm -q bats container-selinux golang podman podman-tests selinux-policy

# Run podman system tests
bats /usr/share/podman/test/system/410-selinux.bats
