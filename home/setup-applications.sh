#!/usr/bin/env bash
#===============================================================================
# Install packages script (rock-solid, interactive)
# One package per line for safe commenting
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

install_package() {
    local pkg=$1
    if pacman -Qi "$pkg" &>/dev/null; then
        echo "Package $pkg already installed, skipping."
    else
        echo "Installing $pkg..."
        sudo pacman -S --noconfirm "$pkg"
    fi
}

# ======================
# Ask global preferences
# ======================
echo "==============================================="
echo "Package installation script"
echo "==============================================="

if confirm "Do you want to approve each package individually?"; then
    PROMPT_PACKAGES=1
else
    PROMPT_PACKAGES=0
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
    greetd
    greetd-tuigreet
    polkit-gnome
    kwallet
    kwallet5
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
    #iwd
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
# Install loop
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
# Run sections
# ======================
install_section CORE_PACKAGES
install_section HYPRLAND_DESKTOP
install_section AUDIO_VIDEO_TOOLS
install_section THUNAR_ECOSYSTEM
install_section FONTS_THEMES
install_section NETWORKING_PACKAGES
install_section OPTIONAL_PACKAGES

echo "======================================="
echo "Package installation completed!"
echo "======================================="

