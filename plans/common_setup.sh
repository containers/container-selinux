#!/usr/bin/env bash

# Clean all prior dnf metadata
dnf clean all

# Disable rhcontainerbot/packit-builds to avoid testing with
# packages built from unmerged content of other repos.
dnf -y copr disable rhcontainerbot/packit-builds

# Fetch podman and other dependencies from rhcontainerbot/podman-next.
. /etc/os-release
if [ $(NAME) == "CentOS Stream" ]; then
    dnf -y copr enable rhcontainerbot/podman-next centos-stream+epel-next-$(VERSION)
else
    dnf -y copr enable rhcontainerbot/podman-next
fi
dnf -y --disablerepo=testing-farm-* install bats golang podman podman-tests
