#!/usr/bin/env bash

# Packit's default fix-spec-file often doesn't fetch version string correctly.
# This script handles any custom processing of the dist-git spec file and gets used by the
# fix-spec-file action in .packit.yaml

set -eo pipefail

# Set path to rpm spec file
SPEC_FILE=rpm/container-selinux.spec

# Get Version from HEAD
HEAD_VERSION=$(grep '^policy_module' container.te | sed 's/[^0-9.]//g')

# Generate source tarball
git archive --prefix=container-selinux-$HEAD_VERSION/ -o rpm/container-selinux-$HEAD_VERSION.tar.gz HEAD

# RPM Spec modifications

# Update Version in spec with Version from container.te
sed -i "s/^Version:.*/Version: $HEAD_VERSION/" $SPEC_FILE

# Update Release in spec with Packit's release envvar
sed -i "s/^Release:.*/Release: $PACKIT_RPMSPEC_RELEASE%{?dist}/" $SPEC_FILE

# Update Source tarball name in spec
sed -i "s/^Source:.*.tar.gz/Source: %{name}-$HEAD_VERSION.tar.gz/" $SPEC_FILE
