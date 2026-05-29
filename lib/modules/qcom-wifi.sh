#!/usr/bin/env bash

_qcom_wifi_makepkg() {
    _msg2 "Building Qualcomm WiFi packages..."

    cd "${_BUILDDIR}" || exit 1

    _makepkg_git_clone "https://github.com/linux-surface/aarch64-packages" "ls"

    _makepkg_build_install "${_BUILDDIR}/ls/qmic"
    _makepkg_build_install "${_BUILDDIR}/ls/qrtr"
    _makepkg_build_install "${_BUILDDIR}/ls/tqftpserv"
    _makepkg_build_install "${_BUILDDIR}/ls/pd-mapper"

    # rmtfs-dummy tracks linux-msm/rmtfs HEAD and bundles a "-o optarg" getopt
    # fix as a patch. Upstream merged that fix (14cb1ee, "rmtfs: Fix command
    # line argument parsing for '-o' optarg"), so the patch now fails against
    # HEAD ("patch failed: rmtfs.c:505 ... patch does not apply") and aborts
    # prepare(). A previous attempt pinned the source to the parent commit via a
    # `#commit=` fragment, but makepkg in the chroot does not honour it and still
    # builds HEAD. Instead, tolerate the redundant optarg patch: make its
    # `git apply` a no-op when it does not apply, while keeping the essential
    # /var/lib/rmtfs redirect patch strict so a real breakage still fails loudly.
    # Editing only the prepare() line leaves source=()/sha256sums=() intact.
    sed -i '/git apply.*optarg\.patch/ s/$/ || true/' \
        "${_BUILDDIR}/ls/rmtfs-dummy/PKGBUILD"

    _makepkg_build_install "${_BUILDDIR}/ls/rmtfs-dummy"

    cd /
}

_qcom_wifi_services() {
    _msg2 "Enabling Qualcomm WiFi services..."

    systemctl enable pd-mapper.service
    systemctl enable tqftpserv.service
    systemctl enable rmtfs.service
}

install() {
    _qcom_wifi_makepkg
    _qcom_wifi_services
}
