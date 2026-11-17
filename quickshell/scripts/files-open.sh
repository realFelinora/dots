#!/bin/sh
# Uygulama menüsünden / xdg-open'dan dosya yöneticisini yeni pencerede açar.
# Argüman yoksa ev klasörü; file:// adresleri yola çevrilir.
[ $# -eq 0 ] && set -- "$HOME"
for a in "$@"; do
    case $a in
        file://*) p=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.unquote(urllib.parse.urlparse(sys.argv[1]).path))' "$a") ;;
        *) p=$a ;;
    esac
    [ -f "$p" ] && p=$(dirname -- "$p")
    qs -c felinora-shell ipc call felinora files "$p"
done
