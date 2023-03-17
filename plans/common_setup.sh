#!/usr/bin/env bash

# Disable rhcontainerbot/packit-builds to avoid testing with
# packages built from unmerged content of other repos.
dnf -y copr disable rhcontainerbot/packit-builds

# Fetch podman and other dependencies from rhcontainerbot/podman-next.
dnf -y copr enable rhcontainerbot/podman-next
dnf -y install bats golang podman podman-tests
