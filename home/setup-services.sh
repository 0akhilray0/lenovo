#!/usr/bin/env bash
#===============================================================================
# Enable system and user services script (rock-solid, interactive)
# One service per line for safe commenting
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

enable_service() {
    local svc=$1
    local mode=$2
    if [ "$mode" = "system" ]; then
        if systemctl list-unit-files | grep -q "^$svc.*enabled"; then
            echo "System service $svc already enabled, skipping."
        else
            echo "Enabling system service $svc..."
            sudo systemctl enable --now "$svc"
        fi
    else
        if systemctl --user list-unit-files | grep -q "^$svc.*enabled"; then
            echo "User service $svc already enabled, skipping."
        else
            echo "Enabling user service $svc..."
            systemctl --user enable --now "$svc"
        fi
    fi
}

disable_service() {
    local svc=$1
    echo "Disabling $svc..."
    sudo systemctl disable --now "$svc"
}

# ======================
# Ask global preferences
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
# Define services
# ======================
SYSTEM_SERVICES=(
    NetworkManager
    greetd
    bluetooth
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
)

USER_SERVICES=(
    pipewire
    pipewire-pulse
    wireplumber
    gnome-keyring-daemon
)

OPTIONAL_SERVICES=(
    kwalletmanager
)

# ======================
# Enable loop
# ======================
enable_section() {
    local section_name=$1[@]
    local services=("${!section_name}")
    local mode=$2
    echo "---------------------------------------"
    echo "Enabling section: ${1}"
    echo "---------------------------------------"

    for svc in "${services[@]}"; do
        [[ $svc == \#* ]] && continue
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
# Run sections
# ======================
enable_section SYSTEM_SERVICES system
enable_section USER_SERVICES user
enable_section OPTIONAL_SERVICES system

# Disable iwd safely
echo "---------------------------------------"
if confirm "Do you want to disable iwd.service?"; then
    disable_service iwd
else
    echo "iwd.service left enabled"
fi

echo "======================================="
echo "All services processed!"
echo "======================================="

