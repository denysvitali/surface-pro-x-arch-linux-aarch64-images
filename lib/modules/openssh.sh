#!/usr/bin/env bash

install() {
    _msg2 "Enabling sshd.service for headless access..."

    # openssh is installed via packages/install. Enabling sshd gives headless
    # access to the tablet. The ALARM rootfs ships default credentials
    # (alarm/alarm, root/root); change them after first boot.
    systemctl enable sshd.service
}
