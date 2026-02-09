#!/usr/bin/env bash
#===============================================================================
# Service enablement script (systemd + xdg portals done right)
#===============================================================================

confirm() {
    while true; do
        read -rp "$1 (y/n): " yn
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}

unit_exists() {
    local svc="$1"
    local mode="$2"

    if [ "$mode" = "system" ]; then
        systemctl list-unit-files "$svc.service" &>/dev/null
    else
        systemctl --user list-unit-files "$svc.service" &>/dev/null
    fi
}

enable_service() {
    local svc="$1"
    local mode="$2"

    if ! unit_exists "$svc" "$mode"; then
        echo "Unit $svc does not exist, skipping."
        return
    fi

    if [ "$mode" = "system" ]; then
        if systemctl is-enabled "$svc" &>/dev/null; then
            echo "System service $svc already enabled, skipping."
        else
            echo "Enabling system service $svc..."
            sudo systemctl enable --now "$svc"
        fi
    else
        if systemctl --user is-enabled "$svc" &>/dev/null; then
            echo "User service $svc already enabled, skipping."
        else
            echo "Enabling user service $svc..."
            systemctl --user enable --now "$svc"
        fi
    fi
}

handle_portal() {
    local portal="$1"
    echo "Handling portal: $portal"

    # Check package
    if ! pacman -Q "$portal" &>/dev/null; then
        echo "✖ Package $portal NOT installed"
        return
    fi
    echo "✔ Package $portal installed"

    # If a user service exists, enable it
    if systemctl --user list-unit-files "$portal.service" &>/dev/null; then
        if systemctl --user is-enabled "$portal" &>/dev/null; then
            echo "✔ $portal user service already enabled"
        else
            echo "Enabling $portal user service..."
            systemctl --user enable --now "$portal" 2>/dev/null || \
                echo "⚠ $portal is D-Bus activated (enable skipped)"
        fi
    else
        echo "ℹ $portal has no user service (D-Bus activated)"
    fi
}

disable_service() {
    local svc="$1"

    if systemctl list-unit-files "$svc.service" &>/dev/null; then
        echo "Disabling $svc..."
        sudo systemctl disable --now "$svc"
    else
        echo "Unit $svc does not exist, skipping."
    fi
}

# ======================
# Preferences
# ======================
echo "==============================================="
echo "Service enablement script"
echo "==============================================="

if confirm "Do you want to approve each service individually?"; then
    PROMPT_SERVICES=1
else
    PROMPT_SERVICES=0
fi

# ======================
# Services
# ======================
SYSTEM_SERVICES=(
    NetworkManager
    greetd
    bluetooth
)

USER_SERVICES=(
    pipewire
    pipewire-pulse
    wireplumber
    gnome-keyring-daemon
)

PORTALS=(
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

)

# ======================
# Enable sections
# ======================
enable_section() {
    local section_name=$1[@]
    local services=("${!section_name}")
    local mode="$2"

    echo "---------------------------------------"
    echo "Enabling section: $1"
    echo "---------------------------------------"

    for svc in "${services[@]}"; do
        if [ "$PROMPT_SERVICES" -eq 1 ]; then
            if confirm "Enable $svc?"; then
                enable_service "$svc" "$mode"
            else
                echo "Skipping $svc"
            fi
        else
            enable_service "$svc" "$mode"
        fi
    done
}

# ======================
# Run
# ======================
enable_section SYSTEM_SERVICES system
enable_section USER_SERVICES user

echo "---------------------------------------"
echo "Handling xdg portals"
echo "---------------------------------------"
for portal in "${PORTALS[@]}"; do
    handle_portal "$portal"
done

echo "---------------------------------------"
if confirm "Do you want to disable iwd.service?"; then
    disable_service iwd
else
    echo "iwd.service left enabled"
fi

echo "======================================="
echo "All services processed!"
echo "======================================="

