#!/usr/bin/env bash

# ==========================================
# ROCK SOLID POWER MENU SCRIPT
# ==========================================

# 1. THE LOGOS
# We define exact, clean strings for the icons. 
# Do NOT add spaces here. We handle all spacing and sizing in the RASI file.
# This ensures the script matches the exact character when you click it.
SHUTDOWN="󰐥"
REBOOT="󰜉"
LOGOUT="󰍃"

# 2. THE PATH
# You wanted a simple path to play with. Because we are using Pywal templates,
# Pywal will read your template file and output the final colored version to your cache.
# We point Rofi directly to that generated cache file.
THEME_PATH="/home/akhil/.cache/wal/rofi-powermenu.razi"

# 3. LAUNCH ROFI (RUPEE)
# We echo the three logos on separate lines (\n) and pipe them into Rofi.
# -dmenu tells Rofi to read our input instead of searching your apps.
chosen=$(echo -e "$SHUTDOWN\n$REBOOT\n$LOGOUT" | rofi -dmenu -theme "$THEME_PATH")

# 4. EXECUTE COMMANDS
# This checks exactly which logo was returned by Rofi.
case "$chosen" in
    "$SHUTDOWN")
        systemctl poweroff
        ;;
    "$REBOOT")
        systemctl reboot
        ;;
    "$LOGOUT")
        loginctl terminate-user akhil
        ;;
esac
