#!/usr/bin/env bash
#===============================================================================
# Final Rock-Solid Interactive Arch Linux Setup Script
# One package/service per line for safe commenting
#===============================================================================

# ======================
# Helper functions
# ======================
confirm() {
    while true; do
        read -rp "$1 (y/n): " yn
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}

install_package() {
    local pkg=$1
    if pacman -Qi "$pkg" &>/dev/null; then
        echo "Package $pkg already installed, skipping."
    else
        echo "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    fi
}

enable_service() {
    local svc=$1
    if systemctl list-unit-files | grep -q "^$svc.*enabled"; then
        echo "Service $svc already enabled, skipping."
    else
        echo "Enabling service $svc..."
        sudo systemctl enable --now "$svc"
    fi
}

disable_service() {
    local svc=$1
    if systemctl list-unit-files | grep -q "^$svc.*enabled"; then
        echo "Disabling service $svc..."
        sudo systemctl disable --now "$svc"
    else
        echo "Service $svc already disabled, skipping."
    fi
}

# ======================
# Ask global preferences
# ======================
echo "==============================================="
echo "Interactive Arch Linux Setup Script (Final)"
echo "==============================================="

if confirm "Do you want to approve each package individually?"; then
    PROMPT_PACKAGES=1
else
    PROMPT_PACKAGES=0
fi

if confirm "Do you want to approve each service individually?"; then
    PROMPT_SERVICES=1
else
    PROMPT_SERVICES=0
fi

# ======================
# Define package sections
# ======================

CORE_PACKAGES=(
    #base
    #base-devel
    #linux-lts
    #linux-firmware
    #efibootmgr
    #os-prober
    #zram-generator
)

HYPRLAND_DESKTOP=(
    hyprland
    waybar
    swaync
    hyprpaper
    ghostty
    rofi
    nm-applet
    pipewire
    pipewire-pulse
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
)

AUDIO_VIDEO_TOOLS=(
    playerctl
    wpctl
    ffmpegthumbnailer
    mpv
    cava
    btop
)

THUNAR_ECOSYSTEM=(
    thunar
    gvfs
    gvfs-afc
    gvfs-mtp
    gvfs-nfs
    gvfs-smb
    gvfs-wsdd
    tumbler
    file-roller
    thunar-volman
    udiskie
    thunar-archive-plugin
    thunar-media-tags-plugin
    thunar-shares-plugin
    thunar-vcs-plugin
)

FONTS_THEMES=(
    noto-fonts-emoji
    ttf-fira-code
    ttf-firacode-nerd
    adw-gtk-theme
    qt5ct
    qt6ct
    gnome-themes-extra
)

NETWORKING_PACKAGES=(
    networkmanager
    blueman
    bluez
    bluez-utils
    iwd
)

OPTIONAL_PACKAGES=(
    kwalletmanager
    proton-vpn-gtk-app
    speedtest-cli
    tgpt
    yazi
    fastfetch
    cmatrix
    catfish
)

# ======================
# Define services
# ======================

SYSTEM_SERVICES=(
    NetworkManager.service
    bluetooth.service
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
)

USER_SERVICES=(
    waybar.service
    swaync.service
    hyprpaper.service
    gnome-keyring-daemon.service
    xdg-desktop-portal-hyprland.service
)

OPTIONAL_SERVICES=(
    kwalletmanager.service
    #zram-generator.service
)

# ======================
# Install packages
# ======================
install_section() {
    local section_name=$1[@]
    local packages=("${!section_name}")
    echo "---------------------------------------"
    echo "Installing section: ${1}"
    echo "---------------------------------------"

    for pkg in "${packages[@]}"; do
        [[ $pkg == \#* ]] && continue
        if [ "$PROMPT_PACKAGES" -eq 1 ]; then
            if confirm "Install package $pkg?"; then
                install_package "$pkg"
            else
                echo "Skipping package $pkg"
            fi
        else
            install_package "$pkg"
        fi
    done
}

# ======================
# Enable services
# ======================
enable_section() {
    local section_name=$1[@]
    local services=("${!section_name}")
    echo "---------------------------------------"
    echo "Enabling section: ${1}"
    echo "---------------------------------------"

    for svc in "${services[@]}"; do
        [[ $svc == \#* ]] && continue
        if [ "$PROMPT_SERVICES" -eq 1 ]; then
            if confirm "Enable service $svc?"; then
                enable_service "$svc"
            else
                echo "Skipping service $svc"
            fi
        else
            enable_service "$svc"
        fi
    done
}

# ======================
# Run sections
# ======================
install_section CORE_PACKAGES
install_section HYPRLAND_DESKTOP
install_section AUDIO_VIDEO_TOOLS
install_section THUNAR_ECOSYSTEM
install_section FONTS_THEMES
install_section NETWORKING_PACKAGES
install_section OPTIONAL_PACKAGES

enable_section SYSTEM_SERVICES
enable_section USER_SERVICES
enable_section OPTIONAL_SERVICES

# ======================
# Disable iwd safely
# ======================
echo "---------------------------------------"
echo "Disabling iwd.service as requested"
echo "---------------------------------------"
if confirm "Do you want to disable iwd.service?"; then
    disable_service iwd.service
else
    echo "iwd.service left enabled"
fi

echo "======================================="
echo "All done! Your system should now be set up."
echo "======================================="

