#!/usr/bin/env bash

_bluetooth_firmware() {
    _msg2 "Linking QCA Bluetooth firmware (chip ID 01 -> 21)..."

    # The Surface Pro X Bluetooth controller probes for firmware with the "01"
    # chip-ID suffix, while linux-firmware-msft-surface-pro-x-qcom ships the
    # blobs with the "21" suffix. Alias the expected names onto the real files
    # when they are present (see the linux-surface Surface Pro X Bluetooth wiki).
    local qca="/usr/lib/firmware/qca"

    local files=(
        "crbtfw21.tlv:crbtfw01.tlv"
        "crnv21.bin:crnv01.bin"
        "crnv21.b3c:crnv01.b3c"
        "crnv21.b44:crnv01.b44"
        "crnv21.b45:crnv01.b45"
        "crnv21.b46:crnv01.b46"
        "crnv21.b47:crnv01.b47"
        "crnv21.b71:crnv01.b71"
    )

    local pair target link
    for pair in "${files[@]}"; do
        target="${pair%%:*}"
        link="${pair##*:}"

        if [[ -e "${qca}/${target}" ]]; then
            ln -sf "${target}" "${qca}/${link}"
        else
            _msg2 "  skip: ${qca}/${target} not found"
        fi
    done
}

_bluetooth_services() {
    _msg2 "Enabling bluetooth.service..."
    systemctl enable bluetooth.service
}

install() {
    _bluetooth_firmware
    _bluetooth_services
}
