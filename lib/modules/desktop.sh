#!/usr/bin/env bash

# Hyprland desktop, loosely modelled on Omarchy (https://github.com/basecamp/omarchy).
# Omarchy is x86-centric and pulls a lot of AUR packages, so instead of running its
# installer we assemble an equivalent Wayland stack from native ALARM/aarch64 packages
# (hyprland + waybar + mako + wofi + hyprlock/hypridle + pipewire) and ship a small set
# of Omarchy-flavoured configs via /etc/skel. The packages themselves are listed in the
# profile's packages/install; this module wires up the user, services and configs.

_DESKTOP_USER="alarm"

_desktop_user_groups() {
    _msg2 "Adding ${_DESKTOP_USER} to desktop groups..."

    # video/render: GPU (freedreno) and DRM access; input: libinput/seat devices;
    # audio: PipeWire/ALSA; wheel: sudo; storage/network: removable media + NM.
    local groups="wheel video render input audio storage network"

    local g
    for g in ${groups}; do
        # getent group exists for all of these on a base system; -a is idempotent.
        gpasswd -a "${_DESKTOP_USER}" "${g}" > /dev/null 2>&1 || \
            _msg2 "  skip: group ${g} not present"
    done
}

_desktop_sudo() {
    _msg2 "Granting wheel passwordless-free sudo..."

    # Members of wheel may run sudo (prompting for their password). This matches
    # the Arch default sudoers comment but enables it via a drop-in so we never
    # edit the shipped sudoers file.
    #
    # NB: this module defines an install() hook, so the coreutils `install`
    # command would resolve to that function (shell functions shadow externals)
    # and recurse infinitely -- use mkdir/chmod instead.
    mkdir -p /etc/sudoers.d
    chmod 0750 /etc/sudoers.d
    echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
    chmod 0440 /etc/sudoers.d/10-wheel
}

_desktop_skel() {
    _msg2 "Seeding desktop configs into ${_DESKTOP_USER}'s home..."

    # The configs are shipped in profiles/<name>/base/etc/skel by the profile.
    # /etc/skel only applies to users created *after* it is populated, and the
    # ALARM 'alarm' user already exists, so copy the configs in explicitly and
    # fix ownership. Existing files are not clobbered (-n) so user edits survive
    # a rebuild-in-place, but on a fresh image the home is empty anyway.
    local home="/home/${_DESKTOP_USER}"

    if [[ ! -d "${home}" ]]; then
        _msg2 "  skip: ${home} does not exist"
        return
    fi

    cp -rn /etc/skel/. "${home}/" 2>/dev/null || true
    chown -R "${_DESKTOP_USER}:${_DESKTOP_USER}" "${home}"
}

_desktop_services() {
    _msg2 "Enabling PipeWire for all users..."

    # PipeWire ships user units; enable them globally so every login (incl. the
    # greetd session) gets sound + screen-sharing without a per-user `systemctl
    # --user enable`, which we cannot run in the chroot.
    systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service \
        > /dev/null 2>&1 || _msg2 "  warning: could not enable PipeWire user units"
}

install() {
    _desktop_user_groups
    _desktop_sudo
    _desktop_skel
    _desktop_services
}
