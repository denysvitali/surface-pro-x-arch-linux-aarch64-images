#!/usr/bin/env bash

_qcom_wifi_makepkg() {
    _msg2 "Building Qualcomm WiFi packages..."

    cd "${_BUILDDIR}" || exit 1

    _makepkg_git_clone "https://github.com/linux-surface/aarch64-packages" "ls"

    _makepkg_build_install "${_BUILDDIR}/ls/qmic"
    _makepkg_build_install "${_BUILDDIR}/ls/qrtr"
    _makepkg_build_install "${_BUILDDIR}/ls/tqftpserv"
    _makepkg_build_install "${_BUILDDIR}/ls/pd-mapper"

    # Pin rmtfs to the commit before linux-msm/rmtfs upstreamed the "-o optarg"
    # getopt fix (14cb1ee, 2026-01-03). rmtfs-dummy still carries that fix as a
    # bundled patch, which no longer applies against the unpinned HEAD
    # ("patch failed: rmtfs.c:505 ... patch does not apply"). Pinning the parent
    # commit lets both bundled patches apply cleanly again.
    local rmtfs_commit="f9847a777c4b1bd4c9dfdef457e46e8c5dc8e753"
    sed -i \
        "s|github.com/linux-msm/rmtfs.git|github.com/linux-msm/rmtfs.git#commit=${rmtfs_commit}|" \
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
