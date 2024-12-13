#!/usr/bin/env bash

set -exo pipefail

cat /etc/redhat-release

if [[ "$(id -u)" -ne 0 ]];then
    echo "Please run as superuser"
    exit 1
fi

if [[ -z "$1" ]]; then
    echo -e "Usage: $(basename ${BASH_SOURCE[0]}) TEST_TYPE\nTEST_TYPE can be 'e2e' or 'system'\n"
    exit 1
fi

TEST_TYPE=$1

# Remove testing-farm repos if they exist as these interfere with the packages
# we want to install, especially when podman-next copr is involved
rm -f /etc/yum.repos.d/tag-repository.repo

# Fetch and extract latest podman source from the highest priority dnf repo
# NOTE: On upstream pull-requests, the srpm will be fetched from the
# podman-next copr while on bodhi updates, it will be fetched from Fedora's
# official repos.
PODMAN_DIR=$(mktemp -d)
pushd $PODMAN_DIR

# Download podman and podman-tests rpms, along with podman srpm
dnf download podman podman-tests
# Download srpm, srpm opts differ between dnf and dnf5
rpm -q dnf5 && dnf download --srpm podman || dnf download --source podman

# Ensure podman-tests RPM and podman SRPM version-release match
# NOTE: podman RPM and podman-tests RPM matching is ensured by podman.spec so
# matching podman-tests and podman srpm is sufficient here.
PODMAN_TESTS_VERSION=$(ls podman-tests* | sed -e "s/.$(uname -m).rpm//" -e "s/podman-tests-//")
PODMAN_SRPM_VERSION=$(ls podman*.src.rpm | sed -e "s/.src.rpm//" -e "s/podman-//")
if [[ "$PODMAN_TESTS_VERSION" != "$PODMAN_SRPM_VERSION" ]]; then
    echo "podman-tests and podman srpm version-release don't match"
    exit 1
fi

# Install downloaded podman and podman-tests rpms
dnf -y install ./podman*.$(uname -m).rpm

# Extract and untar podman source from srpm
rpm2cpio $(ls podman*.src.rpm) | cpio -di
tar zxf podman*.tar.gz

popd

# Print versions of distro and installed packages
rpm -q bats container-selinux golang podman podman-tests selinux-policy

if [[ "$TEST_TYPE" == "e2e" ]]; then
    # /tmp is often unsufficient
    export TMPDIR=/var/tmp

    # dnf5 contains breaking changes
    # Either of `dnf` OR `dnf5` will be installed, never both.
    # To fetch srpm, dnf uses `--source`, dnf5 uses `--srpm`.
    #rpm -q dnf5 && SRPM_OPTS="--srpm" || SRPM_OPTS="--source"

    # Run podman e2e tests
    pushd $PODMAN_DIR/podman-*/test/e2e
    PODMAN_BINARY=/usr/bin/podman go test -v config.go config_amd64.go common_test.go libpod_suite_test.go run_selinux_test.go
    popd
fi

if [[ "$TEST_TYPE" == "system" ]]; then
    # Run podman system tests
    bats /usr/share/podman/test/system/410-selinux.bats
fi
