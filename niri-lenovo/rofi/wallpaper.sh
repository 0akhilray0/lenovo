#!/usr/bin/bash

WALLPAPER_DIR="/home/akhil/decorations/wallpaper"                                      # edit as per your system
IMAGE_PICKER_CONFIG="/home/akhil/.cache/wal/rofi-Wallpaper.razi"                # razi config
WALLPAPER_FILES=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \)) # add other like gif ...
CURRENT_WALLPAPER_FILE=$(basename "$(awww query | awk '{print $NF}')")
ROFI_MENU=""

while IFS= read -r WALLPAPER_PATH; do
  WALLPAPER_NAME=$(basename "$WALLPAPER_PATH")
  if [[ "$WALLPAPER_NAME" == "$CURRENT_WALLPAPER_FILE" ]]; then
    ROFI_MENU+="${WALLPAPER_NAME} (current)\0icon\x1f${WALLPAPER_PATH}\n"
  else
    ROFI_MENU+="${WALLPAPER_NAME}\0icon\x1f${WALLPAPER_PATH}\n"
  fi
done <<<"$WALLPAPER_FILES"

SELECTED_WALLPAPER=$(echo -e "$ROFI_MENU" | rofi -dmenu \
  -p "SEARCH AND SELECT WALLPAPER:" \
  -theme "$IMAGE_PICKER_CONFIG" \
  -markup-rows)

SELECTED_WALLPAPER_NAME=$(echo "$SELECTED_WALLPAPER" | sed 's/ (current)//')

if [[ -n "$SELECTED_WALLPAPER_NAME" ]]; then
  TARGET_WALLPAPER="$WALLPAPER_DIR/$SELECTED_WALLPAPER_NAME"

  # 1. Apply the new wallpaper using awww
  awww img "$TARGET_WALLPAPER" --transition-type any --transition-duration 3
  
  # 2. Tell Pywal to generate colors (quietly, without touching the wallpaper) & matugen for Gtk
  wal -i "$TARGET_WALLPAPER" -n -q 
  matugen image "$TARGET_WALLPAPER" # Generates GTK CSS based on your matugen templates
  
  # 3. Instantly reload Niri to apply the new borders
  niri msg action reload-config

  # 4. Reload Waybar using your custom script
  bash /home/akhil/.config/waybar/scripts/reload.sh
  cp -f "$HOME/.cache/wal/btop" "/home/akhil/.config/btop/themes/matugen.theme" ##RElaods the cava
  cp -f "$HOME/.cache/wal/cava" "$HOME/.config/cava/config" ##RElaods the cava
  pkill -USR2 kitty
  pkill -USR2 cava
  pkill -USR2 btop
fi
