#!/usr/bin/env bash

install() {
    _msg2 "Configuring NetworkManager..."

    # Use iwd as the WiFi backend. iwd handles the Qualcomm WiFi (sc8180x)
    # better than wpa_supplicant on this platform and is already set up by the
    # iwd module, so let NetworkManager drive it.
    mkdir -p /etc/NetworkManager/conf.d
    cat << EOF > /etc/NetworkManager/conf.d/wifi_backend.conf
[device]
wifi.backend=iwd
EOF

    _msg2 "Enabling NetworkManager.service..."
    systemctl enable NetworkManager.service

    # NetworkManager now owns all networking, so make sure systemd-networkd
    # does not fight it for the interfaces.
    _msg2 "Disabling systemd-networkd..."
    systemctl mask systemd-networkd.service systemd-networkd.socket
}
