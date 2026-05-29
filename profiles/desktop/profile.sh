#!/usr/bin/env bash

# Same build flow as the `persistent` profile: a full, persistent ext4 root on
# the USB stick (a desktop is far too large for the RAM-only `default` image).
build() {
    _root_check
    _prepare_sources
    _rootfs_build
    _rootfs_cleanup_full
    _img_prepare_tree_default
    _img_build
}
