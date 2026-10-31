#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (c) 2026 NVIDIA Corporation
set -euo pipefail

# Run against a linked policy containing the CDI changes, without loading it
# into the kernel. An optional binary policy argument selects an offline store.
policy=()
if [[ $# -gt 0 ]]; then
    policy=("$1")
fi

expect_permission() {
    local source=$1 class=$2 permission=$3 expected=$4 result
    result=$(sesearch --allow -s "$source" -t container_cdi_t \
        -c "$class" -p "$permission" "${policy[@]}")
    if [[ "$expected" == yes ]]; then
        [[ -n "$result" ]] || { echo "missing $source $class:$permission" >&2; exit 1; }
    else
        [[ -z "$result" ]] || { echo "unexpected $source $class:$permission: $result" >&2; exit 1; }
    fi
}

for permission in create write rename unlink; do
    expect_permission container_device_plugin_t file "$permission" yes
done
expect_permission container_device_plugin_t file execute no
for source in container_runtime_t container_kvm_t; do
    expect_permission "$source" file read yes
    expect_permission "$source" dir watch yes
done
for permission in create write rename unlink execute; do
    expect_permission container_t file "$permission" no
    expect_permission container_kvm_t file "$permission" no
done
for permission in write add_name remove_name; do
    expect_permission container_t dir "$permission" no
    expect_permission container_kvm_t dir "$permission" no
done
sesearch --type_trans -s kubelet_t -t var_run_t -c dir "${policy[@]}" |
    grep -q 'container_cdi_t cdi;'
