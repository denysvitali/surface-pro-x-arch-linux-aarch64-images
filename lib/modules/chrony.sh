#!/usr/bin/env bash

install() {
    _msg2 "Enabling chronyd.service..."

    # chrony replaces systemd-timesyncd for NTP time synchronization.
    systemctl enable chronyd.service
}
