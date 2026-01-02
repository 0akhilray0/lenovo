if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ll 'ls -la'
alias yazi 'sudo yazi'
alias cls 'clear'
#DUAL BOOT WINDOWS COMMAND
alias windows 'sudo grub-reboot "Windows11"; sudo reboot'

alias waydroid-start='sudo systemctl start waydroid-container && waydroid session start && echo "Waydroid started. Wait 10–20s for Android to fully boot."'

alias waydroid-stop='waydroid session stop && sudo systemctl stop waydroid-container && \
echo "Waydroid stopped, RAM freed."'


set -Ux EDITOR nvim
