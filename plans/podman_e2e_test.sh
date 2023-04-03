#!/usr/bin/env bash

# Copr repo setup handled in common_setup.sh
. ./plans/common_setup.sh

# Fetch and prep Podman source from latest SRPM on
# rhcontainerbot/podman-next copr
dnf --disablerepo=* --enablerepo=copr:copr.fedorainfracloud.org:rhcontainerbot:podman-next download --source podman
rpm2cpio podman*.src.rpm | cpio -di
tar zxf podman*.tar.gz
cd podman/test/e2e

# Run SELinux specific Podman e2e tests
PODMAN_BINARY=/usr/bin/podman go test -v config.go config_amd64.go common_test.go libpod_suite_test.go run_selinux_test.go
