#!/usr/bin/env bash

set -eox pipefail

cat /etc/redhat-release
rpm -q container-selinux golang podman
if [[ -f /etc/fedora-release ]]; then
    export TMPDIR=/var/tmp
fi
dnf --disablerepo=* --enablerepo=copr:copr.fedorainfracloud.org:rhcontainerbot:podman-next download --source podman
rpm2cpio podman*.src.rpm | cpio -di
tar zxf podman-*-dev.tar.gz
cd podman-*-dev/test/e2e
PODMAN_BINARY=/usr/bin/podman go test -v config.go config_amd64.go common_test.go libpod_suite_test.go run_selinux_test.go
