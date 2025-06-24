#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/aserdev-yt/aserdev-plymouth-theme.git"
CLONE_DIR="/tmp/aserdev-plymouth-theme-$$"
THEME_NAME="aserdev"
PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
GRUB_DEFAULT_FILE="/etc/default/grub"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d%H%M%S)"

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "🚨 Run as root: sudo $0"
        exit 1
    fi
}

require_command() {
    if ! command -v "$1" &>/dev/null; then
        echo "🚨 '$1' not found. Install it and rerun."
        exit 1
    fi
}

preflight() {
    require_command git
    require_command update-initramfs
    require_command update-grub
}

install_packages() {
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y git plymouth plymouth-themes
}

clone_repo() {
    rm -rf "$CLONE_DIR"
    git clone "$REPO_URL" "$CLONE_DIR"
}

copy_theme() {
    if [ -d "$CLONE_DIR/$THEME_NAME" ]; then
        SRC="$CLONE_DIR/$THEME_NAME"
    else
        FIRST=$(find "$CLONE_DIR" -maxdepth 1 -mindepth 1 -type d | head -n1)
        SRC="$FIRST"
        THEME_NAME=$(basename "$FIRST")
    fi
    mkdir -p "$PLYMOUTH_THEMES_DIR"
    cp -r "$SRC" "$PLYMOUTH_THEMES_DIR/$THEME_NAME"
}

set_default_theme() {
    plymouth-set-default-theme "$THEME_NAME"
}

rebuild_initramfs() {
    update-initramfs -u
}

update_grub_cfg() {
    cp "$GRUB_DEFAULT_FILE" "$GRUB_DEFAULT_FILE$BACKUP_SUFFIX"
    if ! grep -Eq 'splash' "$GRUB_DEFAULT_FILE"; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"/' "$GRUB_DEFAULT_FILE"
    fi
    update-grub
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
    update_grub_cfg
    cleanup
    echo "🎉 Done! Reboot and enjoy your fresh Plymouth theme: sudo reboot"
}

main "$@"
