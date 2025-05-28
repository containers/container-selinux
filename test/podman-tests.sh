#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release

if [[ "$(id -u)" -ne 0 ]];then
    echo "Please run as superuser"
    exit 1
fi

if [[ -z "$1" ]]; then
    echo -e "Usage: $(basename "${BASH_SOURCE[0]}") TEST_TYPE\nTEST_TYPE can be 'e2e' or 'system'\n"
    exit 1
fi

TEST_TYPE=$1

export PODMAN_BINARY=/usr/bin/podman

# Remove testing-farm repos if they exist as these interfere with the packages
# we want to install, especially when podman-next copr is involved
rm -f /etc/yum.repos.d/tag-repository.repo

for pkg in container-selinux crun golang podman podman-tests selinux-policy; do
    if ! rpm -q "$pkg"; then
        continue
    fi
done

if [[ "$TEST_TYPE" == "e2e" ]]; then
    # /tmp is often unsufficient
    export TMPDIR=/var/tmp

    # Fetch and extract latest podman source from the highest priority dnf repo
    # NOTE: On upstream pull-requests, the srpm will be fetched from the
    # podman-next copr while on bodhi updates, it will be fetched from Fedora's
    # official repos.
    PODMAN_DIR=$(mktemp -d)
    pushd "$PODMAN_DIR"

    # Download srpm, srpm opts differ between dnf and dnf5
    if ! rpm -q dnf5; then
        dnf download --source podman
    else
        dnf download --srpm podman
    fi

    # Extract and untar podman source from srpm
    rpm2cpio "$(ls podman*.src.rpm)" | cpio -di
    tar zxf ./*.tar.gz

    popd

    if [[ "$(arch)" == "x86_64" ]]; then
        ARCH=amd64
    else
        ARCH=arm64
    fi

    # Run podman e2e tests
    pushd "$PODMAN_DIR"/podman-*/test/e2e
    go test -v config.go config_test.go config_"$ARCH".go common_test.go libpod_suite_test.go run_selinux_test.go
    go test -v config.go config_test.go config_"$ARCH".go common_test.go libpod_suite_test.go checkpoint_test.go
    popd
fi

if [[ "$TEST_TYPE" == "system" ]]; then
    # Run podman system tests
    bats /usr/share/podman/test/system/410-selinux.bats
    bats /usr/share/podman/test/system/520-checkpoint.bats
fi

# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
    echo "Fetching AVC denials..."
    ausearch -m AVC,USER_AVC,SELINUX_ERR,USER_SELINUX_ERR -ts recent
fi
