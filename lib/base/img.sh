#!/usr/bin/env bash

_img_prepare_tree_default() {
    _msg1 "Preparing disk image tree..."
    rm -rf "${_DIR_DISK}"

    _msg2 "Preparing EFI partition..."
    mkdir -p  "${_DIR_DISK_EFI}"
    cp -a "${_DIR_BUILD_ROOTFS}/efi/." "${_DIR_DISK_EFI}"

    _msg2 "Preparing root partition..."
    mkdir -p  "${_DIR_DISK_ROOT}"
    cp -a "${_DIR_BUILD_ROOTFS}/." "${_DIR_DISK_ROOT}"
    rm -rf "${_DIR_DISK_ROOT}/efi"
}

_img_prepare_tree_ramfs() {
    _msg1 "Preparing disk image tree..."
    rm -rf "${_DIR_DISK}"

    _msg2 "Preparing EFI partition..."
    mkdir -p  "${_DIR_DISK_EFI}"
    cp -a "${_DIR_BUILD_ROOTFS}/efi/." "${_DIR_DISK_EFI}"

    _msg2 "Preparing root partition..."
    mkdir -p  "${_DIR_DISK_ROOT}/boot"
    cp -a "${_DIR_BUILD_ROOTFS}/boot/." "${_DIR_DISK_ROOT}/boot"
    rm -f "${_DIR_DISK_ROOT}/boot"/*.img

    local initram="${_DIR_DISK_ROOT}/boot/initramfs-full.img"

    _msg2 "Preparing full initram..."

    local tmpdir;
    tmpdir=$(mktemp -d -t aarch64-archimg-rootfs.XXXXXXXXXX)

    cp -a "${_DIR_BUILD_ROOTFS}/." "${tmpdir}"

    _pushd "${tmpdir}"
    ln -s sbin/init init
    rm -rf "./efi"
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > "${initram}"
    _popd

    rm -rf "${tmpdir}"
}

_img_build() {
    local efs_size;
    local efs_part_size;
    local root_size;
    local root_part_size;
    local disk_size;
    local loopdev;

    _msg1 "Building disk image..."

    _msg2 "Laying out partitions..."

    # compute EFS partition size in MiB
    efs_part_size=$(du -s --block-size=1M "${_DIR_DISK_EFI}" | cut -f1)

    if [[ $efs_part_size -lt 48 ]]; then
        efs_part_size=48
    fi

    # compute root partition size in MiB. du reports space used on the build
    # filesystem, but the target ext4 also needs room for its journal, inode
    # tables and other metadata, all of which scale with the image. A flat
    # +128 MiB only suffices for small profiles; a multi-GB desktop rootfs
    # overflows it ("No space left on device" while copying). Add a proportional
    # margin (25%) plus a fixed floor instead.
    root_size=$(du -s --block-size=1M "${_DIR_DISK_ROOT}" | cut -f1)
    root_part_size=$(( root_size + root_size / 4 + 256 ))

    # compute disk size and create base image
    _msg2 "Allocating disk image..."
    _IMG_DISK="${_DIR_BUILD}/disk.img"

    disk_size=$(( efs_part_size + root_part_size + 8 ))
    # Allocate sparsely: only written blocks consume host disk, which keeps the
    # build within the runner's disk budget for large images (dd reads the holes
    # back as zeros when flashing). Equivalent layout to a zero-filled file.
    truncate -s "${disk_size}M" "${_IMG_DISK}"
    sync

    # partition base image
    _msg2 "Partitioning disk image..."
    sgdisk "${_IMG_DISK}" -n 0:0:+${efs_part_size}MiB -t 0:ef00 -c 0:efi > /dev/null
    sgdisk "${_IMG_DISK}" -n 0:0:+ -t 0:8300 -c 0:boot > /dev/null
    sync

    # format
    _msg2 "Formatting disk image partitions..."
    loopdev=$(losetup --show -f -P "${_IMG_DISK}") || return 1

    mkfs.fat -F 32 "${loopdev}p1" > /dev/null
    # -m 0: this is a removable system image, so do not reserve the default 5%
    # of the root filesystem for root-only use; give that space back to the user
    # (and to fitting the rootfs).
    mkfs.ext4 -m 0 "${loopdev}p2" > /dev/null 2>&1
    sync

    # copy files
    _msg2 "Copying files to EFI partition..."

    mkdir -p "${_DIR_BUILD}/mnt/efi"
    mount "${loopdev}p1" "${_DIR_BUILD}/mnt/efi"
    cp -a "${_DIR_DISK_EFI}/." "${_DIR_BUILD}/mnt/efi"
    sync
    umount "${loopdev}p1"

    _msg2 "Copying files to root partition..."

    mkdir -p "${_DIR_BUILD}/mnt/root"
    mount "${loopdev}p2" "${_DIR_BUILD}/mnt/root"
    cp -a "${_DIR_DISK_ROOT}/." "${_DIR_BUILD}/mnt/root"
    sync
    umount "${loopdev}p2"

    _msg2 "Cleaning up..."
    losetup -d "${loopdev}"
    rm -rf "${_DIR_BUILD:?}/mnt"
}
