#!/usr/bin/env bash

install() {
    _msg2 "Configuring mkinitcpio for USB boot..."

    # The persistent profile boots a real ext4 root off the USB stick. The
    # initramfs therefore needs the Qualcomm USB PHY + DWC3 host-controller
    # drivers and the USB mass-storage drivers, otherwise the root device never
    # appears and the boot stalls in the early-userspace shell.
    #
    #   phy-qcom-qmp            QMP PHY (SuperSpeed USB)
    #   phy-qcom-snps-femto-v2  Synopsys Femto high-speed USB PHY
    #   dwc3-qcom               DesignWare USB3 host controller glue
    #   uas                     USB Attached SCSI (fast USB3 storage)
    #   usb_storage             USB mass-storage class driver
    #
    # The 'block' hook is already part of the default mkinitcpio.conf, so we
    # only need to force-load these modules early via MODULES=().
    #
    # Each module is added with mkinitcpio's '?' optional prefix: on the
    # sc8180x linux-surface kernel several of these PHY/controller drivers are
    # built into the kernel (=y) rather than loadable modules, so a plain
    # MODULES entry makes mkinitcpio abort with "module not found". The '?'
    # prefix tells mkinitcpio to skip any module it cannot find.
    local conf=/etc/mkinitcpio.conf
    local mods="phy-qcom-qmp phy-qcom-snps-femto-v2 dwc3-qcom uas usb_storage"

    local m
    for m in $mods; do
        # Idempotent: only insert a module that is not already listed inside
        # MODULES=(...). Match it as a whole word so e.g. 'uas' does not match
        # a hypothetical 'uas_foo'.
        if grep -Eq "^MODULES=\(.*\b${m}\b.*\)" "$conf"; then
            continue
        fi

        # Insert the module (optional '?' prefix) just before the closing paren
        # of MODULES=(...), preserving any modules that are already present. The
        # leading space is harmless when the list is empty (MODULES=( foo)).
        sed -i -E "s/^(MODULES=\()(.*)(\))/\1\2 ?${m}\3/" "$conf"
    done

    # Tidy up the common 'MODULES=( foo ...' double/leading space cases so the
    # file stays readable; purely cosmetic, never fails.
    sed -i -E 's/^(MODULES=\() +/\1/' "$conf"

    _msg2 "Regenerating all initramfs images..."
    # Rebuild every preset (initramfs-linux-surface.img is the one the
    # persistent grub.cfg loads).
    mkinitcpio -P
}
