#!/usr/bin/env bash

set -exo pipefail

if [[ "$(id -u)" -ne 0 ]];then
    echo "Please run as superuser"
    exit 1
fi

if [[ -z "$1" ]]; then
    echo -e "Usage: podman-tests.sh TEST_TYPE STREAM\nTEST_TYPE can be 'e2e' or 'system'\nSTREAM can be 'upstream' or 'downstream'"
    exit 1
fi

TEST_TYPE=$1
STREAM=$2

# `rhel` macro exists on RHEL, CentOS Stream, and Fedora ELN
# `centos` macro exists only on CentOS Stream
CENTOS_VERSION=$(rpm --eval '%{?centos}')
RHEL_VERSION=$(rpm --eval '%{?rhel}')

# For upstream tests, we need to test with podman and other packages from the
# podman-next copr. For downstream tests (bodhi, errata), we don't need any
# additional setup
if [[ "$STREAM" == "upstream" ]]; then
    # Use CentOS Stream 10 copr target for RHEL-10 until EPEL 10 becomes
    # available
    if [[ -n $CENTOS_VERSION || $RHEL_VERSION -ge 10 ]]; then
        dnf -y copr enable rhcontainerbot/podman-next centos-stream-$CENTOS_VERSION
    else
        dnf -y copr enable rhcontainerbot/podman-next
    fi
    echo "priority=5" >> /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:rhcontainerbot:podman-next.repo
fi

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
# `dnf download podman` fetches main podman rpm and podman srpm on dnf5, only
# the rpm on older dnf versions, so we download srpm separately on those envs
rpm -q dnf5 || dnf download --source podman

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
tar zxf *.tar.gz

popd

# Enable EPEL on RHEL/CentOS Stream envs to fetch bats
if [[ -n $(rpm --eval '%{?rhel}') ]]; then
    # Until EPEL 10 is available use epel-9 for all RHEL and CentOS Stream
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sed -i 's/$releasever/9/g' /etc/yum.repos.d/epel.repo
fi

# Install dependencies for running tests
dnf -y install bats golang

# Print versions of distro and installed packages
cat /etc/redhat-release
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
