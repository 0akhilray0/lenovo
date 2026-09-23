#!/usr/bin/env bash

WALLPAPER_DIR="/home/akhil/Wallpapers"                                          # edit as per your system
IMAGE_PICKER_CONFIG="/home/akhil/.cache/wal/rofi-Wallpaper.razi"                # razi config
CURRENT_WALLPAPER_FILE=$(basename "$(awww query | awk '{print $NF}')")
ROFI_MENU=""

# Fast directory scanning using pure bash parameter expansion instead of subshells
while IFS= read -r WALLPAPER_PATH; do
  WALLPAPER_NAME="${WALLPAPER_PATH##*/}" 
  if [[ "$WALLPAPER_NAME" == "$CURRENT_WALLPAPER_FILE" ]]; then
    ROFI_MENU+="${WALLPAPER_NAME} (current)\0icon\x1f${WALLPAPER_PATH}\n"
  else
    ROFI_MENU+="${WALLPAPER_NAME}\0icon\x1f${WALLPAPER_PATH}\n"
  fi
done < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))

SELECTED_WALLPAPER=$(echo -e "$ROFI_MENU" | rofi -dmenu \
  -p "SEARCH AND SELECT WALLPAPER:" \
  -theme "$IMAGE_PICKER_CONFIG" \
  -markup-rows)

SELECTED_WALLPAPER_NAME=$(echo "$SELECTED_WALLPAPER" | sed 's/ (current)//')

if [[ -n "$SELECTED_WALLPAPER_NAME" ]]; then
  TARGET_WALLPAPER="$WALLPAPER_DIR/$SELECTED_WALLPAPER_NAME"

  # 1. Apply wallpaper in the background 
  awww img "$TARGET_WALLPAPER" --transition-type any --transition-duration 3 &

  # 2. Run Pywal & Matugen concurrently in parallel
  wal -i "$TARGET_WALLPAPER" -n -q &
  # Pass 0 to auto-select the dominant color and bypass the prompt
  matugen image "$TARGET_WALLPAPER" --source-color-index 0 &

  # Wait for both color generators to finish
  wait

  # 3. Reload Niri using the updated subcommand
  niri msg action load-config-file

  # 4. Copy generated configs & reload apps
  cp -f "$HOME/.cache/wal/btop" "/home/akhil/.config/btop/themes/matugen.theme"
  cp -f "$HOME/.cache/wal/cava" "$HOME/.config/cava/config"

  bash /home/akhil/.config/waybar/scripts/reload.sh &
  pkill -USR2 kitty &
  pkill -USR2 cava &
  pkill -USR2 btop &
fi
