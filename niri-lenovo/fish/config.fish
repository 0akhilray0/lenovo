# #######################################################################################
# FISH SHELL CONFIGURATION
# #######################################################################################
# User: akhil
# Shell: Fish (Friendly Interactive Shell)
# System: Arch Linux / Nix Os Sometimes


#For setting the nivm confg to root things 
set -x SUDO_EDITOR nvim

# Documentation: https://fishshell.com/docs/current/
# #######################################################################################
set -g fish_greeting

# ======================================================================================
# INTERACTIVE MODE CHECK
# ======================================================================================
# Commands here only run in interactive shells (not in scripts)
if status is-interactive
    # Commands to run in interactive sessions can go here
end


# ======================================================================================
# GENERAL ALIASES (CONVENIENCE SHORTCUTS)
# ======================================================================================

# List files with details and hidden files
alias ll='ls -la'

# Clear terminal screen
alias cls='clear'


# ======================================================================================
# DUAL BOOT MANAGEMENT
# ======================================================================================

# Boot into Windows on next reboot
# Uses efibootmgr to set Windows (0001) as next boot entry, then reboots
alias windows='sudo efibootmgr -n 0000; sudo reboot'


# ======================================================================================
# NIXOS SYSTEM MANAGEMENT ALIASES
# ======================================================================================

# Rebuild and switch to new NixOS configuration
# This applies changes from configuration.nix immediately
alias nrs='sudo nixos-rebuild switch'

# Edit NixOS system configuration file
# Opens configuration.nix in neovim with sudo privileges
alias nrc='sudo nvim /etc/nixos/configuration.nix'

# Dry-run NixOS rebuild (test without applying changes)
# Shows what would change without actually changing anything
alias nrd='sudo nixos-rebuild dry-build'

# Edit Hyprland window manager configuration
# Opens hyprland.conf in your home directory config folder
alias hyprc='nvim ~/.config/hypr/hyprland.conf'

# ======================================================================================
# FISH CONFIG SHORTCUT
# ======================================================================================

alias fishc='nvim ~/.config/fish/config.fish'


## EDITING NIRI CONFIG SHORTCUT

alias niric='nvim ~/.config/niri/config.kdl'


# ======================================================================================
# NIX PACKAGE MANAGER MAINTENANCE ALIASES
# ======================================================================================

# Delete all old generations and unused packages (garbage collection)
# WARNING: This removes rollback capability - cannot undo!
alias nixc='sudo nix-collect-garbage -d'

# Optimize Nix store by hard-linking duplicate files
# Saves 25-35% disk space by deduplicating identical files
alias nixo='sudo nix-store --optimise'


# ======================================================================================
# ENVIRONMENT VARIABLES
# ======================================================================================

# Set default text editor (used by Git, sudoedit, etc.)
set -gx EDITOR nvim

# Set visual editor (for programs that need GUI editor)
set -gx VISUAL nvim

# Set default terminal emulator
set -gx TERMINAL ghostty


# ======================================================================================
# YAZI FILE MANAGER INTEGRATION
# ======================================================================================
# Yazi function that changes directory when you exit yazi
# This allows "cd on quit" functionality - your terminal changes to the
# directory you navigated to in yazi before exiting

function y
    # Create temporary file to store the current working directory from yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    
    # Run yazi and save the exit directory to temp file
    command yazi $argv --cwd-file="$tmp"
    
    # Read the directory from temp file and change to it
    if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    
    # Clean up temporary file
    rm -f -- "$tmp"
end


# #######################################################################################
# END OF FISH CONFIGURATION
# #######################################################################################
#
# QUICK REFERENCE:
#
# System Management:
#   nrs              - Rebuild and switch NixOS
#   nrc              - Edit configuration.nix
#   nrd              - Dry-run rebuild (test changes)
#   nixc             - Clean up old packages
#   nixo             - Optimize storage
#
# File Management:
#   ll               - List all files with details
#   y                - Open yazi file manager (cd on quit)
#   cls              - Clear screen
#
# Hyprland:
#   hyprc            - Edit Hyprland config
#
# Boot Management:
#   windows          - Reboot into Windows
#
# #######################################################################################
