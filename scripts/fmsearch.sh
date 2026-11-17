#!/bin/sh
# Dosya yöneticisi için "her yerde ara".
#   fmsearch.sh index  GIZLI1:GIZLI2:...          → ev klasörünün dizinini (yeniden) kur
#   fmsearch.sh search LIMIT GIZLILER_GOSTER GIZLI1:GIZLI2:... kelime...
# Ev klasörü için kendi dizinimiz (taze tutulur), geri kalanı sistemin plocate dizini.
# Takılı şifreli kasalar (fuse) ve config.json'daki files.alwaysHidden yolları dizine hiç girmez, sonuçlarda da çıkmaz.
# SPDX-License-Identifier: GPL-3.0-or-later

dir=${XDG_CACHE_HOME:-$HOME/.cache}/fm-ara
db=$dir/ev.db
cmd=$1; shift

case $cmd in
index)
    hide=$(printf '%s' "$1" | tr ':' ' ')
    mkdir -p "$dir"
    # beş dakikadan yeniyse dokunma; aynı anda iki kez kurma
    if [ -f "$db" ] && [ -z "$(find "$db" -mmin +5 2>/dev/null)" ]; then exit 0; fi
    exec 9>"$dir/kilit"
    flock -n 9 || exit 0
    nice -n 19 ionice -c3 updatedb -l 0 -U "$HOME" -o "$db.yeni" \
        --prunepaths "$HOME/.cache $hide" \
        --prunefs "fuse fuse.gocryptfs" 2>/dev/null \
        && mv -f "$db.yeni" "$db"
    rm -f "$db.yeni"
    ;;
search)
    lim=$1 showhid=$2 hide=$3; shift 3
    [ $# -gt 0 ] || exit 0
    big=$((lim * 6))
    {
        if [ -r "$db" ]; then
            plocate -d "$db" -i -b -e -l "$big" -- "$@"
            plocate -i -b -e -l "$big" -- "$@" | grep -v -F -- "$HOME/"
        else
            plocate -i -b -e -l "$big" -- "$@"
        fi
    } 2>/dev/null | awk -v show="$showhid" -v hide="$hide" -v home="$HOME" '
        BEGIN { n = split(hide, H, ":") }
        {
            p = $0
            if (seen[p]++) next
            if (show != "1" && p ~ /\/\./) next
            for (i = 1; i <= n; i++) if (H[i] != "" && (p == H[i] || index(p, H[i] "/") == 1)) next
            print
        }' | head -n "$lim" | tr '\n' '\0' | xargs -0 -r stat -L -c '%F	%s	%Y	%n' -- 2>/dev/null
    ;;
esac
exit 0
