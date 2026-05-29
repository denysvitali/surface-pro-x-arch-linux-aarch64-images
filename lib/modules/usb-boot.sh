#!/usr/bin/env bash

install() {
    _msg2 "Configuring mkinitcpio for USB boot..."

    # For booting a real root off a USB stick (persistent profile) the initramfs
    # needs the Qualcomm USB PHY + dwc3 host-controller drivers and the USB
    # mass-storage drivers, otherwise the root device never appears and the boot
    # stalls in the early-userspace shell. The 'block' hook is already part of
    # the default mkinitcpio.conf, so we only need MODULES=().
    #
    #   phy-qcom-qmp            QMP PHY (SuperSpeed USB)
    #   phy-qcom-snps-femto-v2  Synopsys Femto high-speed USB PHY
    #   dwc3-qcom               DesignWare USB3 host controller glue
    #   uas                     USB Attached SCSI (fast USB3 storage)
    #   usb_storage             USB mass-storage class driver
    #
    # On the sc8180x linux-surface kernel several of these are built into the
    # kernel (=y) rather than loadable modules. Listing a built-in/absent module
    # in MODULES makes mkinitcpio abort with "module not found" (and this
    # mkinitcpio does not understand the '?' optional prefix). So only add the
    # candidates that actually exist as loadable modules for the target kernel.
    local conf=/etc/mkinitcpio.conf
    local candidates="phy-qcom-qmp phy-qcom-snps-femto-v2 dwc3-qcom uas usb_storage"

    # Resolve the target kernel version. The chroot only carries the
    # linux-surface kernel's modules under /usr/lib/modules; modinfo otherwise
    # defaults to the build host's running kernel, which is the wrong tree.
    local kver
    kver="$(ls -1 /usr/lib/modules 2>/dev/null | head -n1)"

    local m
    local add=()
    for m in ${candidates}; do
        if [[ -n "${kver}" ]] && modinfo -k "${kver}" "${m}" >/dev/null 2>&1; then
            add+=("${m}")
        else
            _msg2 "  skip ${m}: not a loadable module for ${kver:-unknown} (built-in or absent)"
        fi
    done

    if [[ ${#add[@]} -gt 0 ]]; then
        local mods="${add[*]}"

        # Insert the resolved modules before the closing paren of MODULES=(...),
        # preserving anything already present, then squash a leading space.
        sed -i -E "s/^(MODULES=\()(.*)(\))/\1\2 ${mods}\3/" "${conf}"
        sed -i -E 's/^(MODULES=\() +/\1/' "${conf}"

        _msg2 "Added initramfs modules: ${mods}"
    fi

    _msg2 "Regenerating all initramfs images..."
    # Rebuild every preset (initramfs-linux-surface.img is the one the
    # persistent grub.cfg loads).
    #
    # The linux-surface sc8180x kernel ships its own mkinitcpio drop-in that
    # lists the platform USB/PHY drivers as '?'-optional modules. Those drivers
    # are built into the kernel (=y), and this mkinitcpio errors out with a
    # non-zero exit on a '?'-optional module it cannot find instead of silently
    # skipping it -- even though it still writes a complete initramfs. Treat that
    # specific case as non-fatal: only fail if the image the bootloader actually
    # loads is missing or empty.
    local img=/boot/initramfs-linux-surface.img
    if ! mkinitcpio -P; then
        if [[ ! -s "${img}" ]]; then
            _msg2 "ERROR: mkinitcpio failed and ${img} was not produced"
            return 1
        fi
        _msg2 "WARNING: mkinitcpio reported errors (optional built-in modules); ${img} present, continuing."
    fi
}
