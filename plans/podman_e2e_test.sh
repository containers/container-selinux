#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release
rpm -q container-selinux golang podman

# /tmp is often unsufficient
export TMPDIR=/var/tmp

# Fetch and extract latest podman source from podman-next copr
dnf --disablerepo=* --enablerepo=copr:copr.fedorainfracloud.org:rhcontainerbot:podman-next download --source podman
rpm2cpio podman*.src.rpm | cpio -di
tar zxf podman-*-dev.tar.gz

# Run podman e2e tests
cd podman-*-dev/test/e2e
PODMAN_BINARY=/usr/bin/podman go test -v config.go config_amd64.go common_test.go libpod_suite_test.go run_selinux_test.go
