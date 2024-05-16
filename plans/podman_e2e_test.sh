#!/usr/bin/env bash

# Do not set -e as we want to work on all results of `rpm -q dnf[5]`.
set -xo pipefail

cat /etc/redhat-release
rpm -q container-selinux golang podman

# /tmp is often unsufficient
export TMPDIR=/var/tmp

# dnf5 contains breaking changes
# Either of `dnf` OR `dnf5` will be installed, never both.
# To fetch srpm, dnf uses `--source`, dnf5 uses `--srpm`.
rpm -q dnf5
if [[ $? -eq 0 ]]; then
    SRPM_OPTS="--srpm"
else
    SRPM_OPTS="--source"
fi

# Fetch and extract latest podman source from podman-next copr
# NOTE: The TMT preparation set podman-next copr to the highest priority so we
# shouldn't need to manipulate any dnf repos here but just fetch from what's
# already set.
dnf download $SRPM_OPTS podman
rpm2cpio podman*.src.rpm | cpio -di
tar zxf podman-*-dev.tar.gz

# Run podman e2e tests
cd podman-*-dev/test/e2e
PODMAN_BINARY=/usr/bin/podman go test -v config.go config_amd64.go common_test.go libpod_suite_test.go run_selinux_test.go
