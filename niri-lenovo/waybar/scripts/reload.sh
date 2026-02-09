#!/bin/sh
# Restart Waybar safely when Hyprland autostart is managing it

# Kill all existing Waybar processes
pkill -f '^waybar$'

# Give it a tiny pause
sleep 0.2

# Start a new Waybar instance
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" waybar &

