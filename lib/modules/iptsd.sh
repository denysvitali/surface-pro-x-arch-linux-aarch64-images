#!/usr/bin/env bash

# iptsd (Intel/Microsoft Precise Touch & Stylus daemon) provides multi-touch
# and pen input on the Surface Pro X. It is not available as a prebuilt aarch64
# package, so build it from source. iptsd builds with meson using
# --wrap-mode=forcefallback, vendoring its C++ dependencies, so the base
# toolchain (base-devel + meson) is enough.
#
# The build is best-effort: single-touch already works via the in-kernel HID
# driver, so a transient network/build failure should not abort the whole
# image. Any failure is logged loudly instead.

_iptsd_build() {
    _msg2 "Building iptsd (multi-touch + pen daemon)..."

    cd "${_BUILDDIR}" || return 1
    _makepkg_git_clone "https://github.com/linux-surface/iptsd" "iptsd" || return 1
    _makepkg_build_install "${_BUILDDIR}/iptsd" || return 1
    cd /
}

install() {
    if ! _iptsd_build; then
        cd /
        _msg2 "WARNING: iptsd build failed; multi-touch and pen will be unavailable (single-touch still works)."
        return 0
    fi

    # iptsd ships its own udev rules and a templated iptsd@.service that udev
    # starts automatically per hidraw touch device, so nothing to enable here.
}
