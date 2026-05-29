#!/usr/bin/env bash

# greetd + tuigreet: a minimal Wayland-native login manager that drops the user
# straight into Hyprland, like Omarchy's greeter. The greetd package creates the
# unprivileged `greeter` user/group for us; we only supply the config and enable
# the service. The greetd.service unit replaces getty on its VT automatically.

install() {
    _msg2 "Configuring greetd (tuigreet -> Hyprland)..."

    # The config file itself is shipped via the profile base tree at
    # /etc/greetd/config.toml; just make sure the directory exists and enable
    # the service here so a profile that forgets the file still boots to a TTY.
    if [[ ! -f /etc/greetd/config.toml ]]; then
        _msg2 "  warning: /etc/greetd/config.toml missing; greetd may fall back to agreety"
    fi

    _msg2 "Enabling greetd.service..."
    systemctl enable greetd.service
}
