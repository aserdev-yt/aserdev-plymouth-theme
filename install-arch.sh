#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/aserdev-yt/aserdev-plymouth-theme.git"
CLONE_DIR="/tmp/aserdev-plymouth-theme-$$"
THEME_NAME="aserdev"
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
GRUB_DEFAULT_FILE="/etc/default/grub"
GRUB_CFG_OUTPUT="/boot/grub/grub.cfg"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d%H%M%S)"

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root: sudo $0"
        exit 1
    fi
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "Command '$cmd' not found."
        exit 1
    fi
}

preflight() {
    require_command git
    require_command pacman
    require_command mkinitcpio
    require_command grub-mkconfig
}

install_packages() {
    pacman -Sy --noconfirm
    pacman -S --noconfirm plymouth plymouth-theme-spinner git
}

clone_repo() {
    rm -rf "$CLONE_DIR"
    git clone "$REPO_URL" "$CLONE_DIR"
}

copy_theme() {
    if [ -d "$CLONE_DIR/$THEME_NAME" ]; then
        SRC_THEME_DIR="$CLONE_DIR/$THEME_NAME"
    else
        local first_dir
        first_dir=$(find "$CLONE_DIR" -maxdepth 1 -mindepth 1 -type d | head -n1)
        SRC_THEME_DIR="$first_dir"
        THEME_NAME=$(basename "$first_dir")
    fi
    mkdir -p "$PLYMOUTH_THEMES_DIR"
    cp -r "$SRC_THEME_DIR" "$PLYMOUTH_THEMES_DIR/$THEME_NAME"
}

set_default_theme() {
    if ! plymouth-set-default-theme "$THEME_NAME"; then
        echo "Failed to set default theme."
        exit 1
    fi
}

rebuild_initramfs() {
    mkinitcpio -P
}

update_grub_cmdline() {
    if [ ! -f "$GRUB_DEFAULT_FILE" ]; then
        echo "$GRUB_DEFAULT_FILE not found."
        return 1
    fi
    cp "$GRUB_DEFAULT_FILE" "$GRUB_DEFAULT_FILE$BACKUP_SUFFIX"
    if ! grep -Eq '^GRUB_CMDLINE_LINUX_DEFAULT=.*\bsplash\b' "$GRUB_DEFAULT_FILE"; then
        sed -E -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"([^\"]*)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 splash\"|" "$GRUB_DEFAULT_FILE"
    fi
    grub-mkconfig -o "$GRUB_CFG_OUTPUT"
}

cleanup() {
    rm -rf "$CLONE_DIR"
}

main() {
    require_root
    preflight
    install_packages
    clone_repo
    copy_theme
    set_default_theme
    rebuild_initramfs
    update_grub_cmdline
    cleanup
    echo "Done! Reboot to see the new Plymouth theme: sudo reboot"
}

main "$@"
