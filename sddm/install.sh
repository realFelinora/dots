#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 realFelinora — Felinora SDDM
#
# Felinora SDDM temasını kurar (yönetici izni gerekir):
#   sudo ./install.sh [--palette ID] [--background RESİM] [--avatar RESİM] [--os ID]
#
#   --palette     pembe | obsidyen | gece | kan | buz | sakura | nane   (varsayılan: pembe)
#   --background  giriş ekranı arka planı (tema klasörüne kopyalanır)
#   --avatar      profil resmi (tema klasörüne kopyalanır)
#   --os          dağıtım logosu (varsayılan: /etc/os-release'ten)
#
# Geri almak için:  sudo rm /etc/sddm.conf.d/10-felinora.conf

set -e

[ "$(id -u)" = 0 ] || { echo "Bu script yönetici izniyle çalışmalı: sudo $0 $*"; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)/felinora"
DEST=/usr/share/sddm/themes/felinora
CONF=/etc/sddm.conf.d/10-felinora.conf
PALETTE=pembe; BG=""; AVATAR=""; OS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --palette)    PALETTE="$2"; shift 2 ;;
        --background) BG="$2"; shift 2 ;;
        --avatar)     AVATAR="$2"; shift 2 ;;
        --os)         OS="$2"; shift 2 ;;
        *) echo "bilinmeyen seçenek: $1"; exit 1 ;;
    esac
done
[ -n "$OS" ] || OS=$(. /etc/os-release 2>/dev/null; echo "${ID:-arch}")

[ -f "$SRC/Main.qml" ] || { echo "tema bulunamadı: $SRC"; exit 1; }

rm -rf "$DEST"
cp -r "$SRC" "$DEST"
mkdir -p "$DEST/assets"

set_key() { sed -i "s|^$1=.*|$1=$2|" "$DEST/theme.conf"; }
set_key palette "$PALETTE"
set_key os "$OS"
if [ -n "$BG" ]; then
    ext="${BG##*.}"; cp "$BG" "$DEST/assets/background.$ext"; set_key background "assets/background.$ext"
fi
if [ -n "$AVATAR" ]; then
    ext="${AVATAR##*.}"; cp "$AVATAR" "$DEST/assets/avatar.$ext"; set_key avatar "assets/avatar.$ext"
fi
chmod -R a+rX "$DEST"

mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=felinora\n' > "$CONF"

echo "✓ tema kuruldu: $DEST"
echo "✓ SDDM ayarı:  $CONF"
echo
echo "Oturumu kapatmadan denemek için:"
echo "  sddm-greeter-qt6 --test-mode --theme $DEST"
