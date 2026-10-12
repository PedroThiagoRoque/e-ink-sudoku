#!/bin/sh
# KUAL entrega o pedido ao plugin; o launcher original do KOReader cuida do aparelho.
set -u

usb_root=${SUDOKU_USB_ROOT:-/mnt/us}
ko_root="$usb_root/koreader"
plugin="$ko_root/plugins/sudoku.koplugin"
target=${1:-menu}

case "$target" in
    menu) ;;
    *) echo 'Destino invalido' >&2; exit 2 ;;
esac

fail() {
    echo "Sudoku: $*" >&2
    if command -v eips >/dev/null 2>&1; then eips 0 2 'Sudoku: veja o tutorial KUAL'; fi
    exit 1
}

[ -f "$ko_root/koreader.sh" ] && [ -f "$ko_root/luajit" ] || fail 'KOReader nao encontrado.'
[ -f "$plugin/main.lua" ] || fail 'Plugin sudoku.koplugin nao instalado.'
if command -v pidof >/dev/null 2>&1 && pidof reader.lua >/dev/null 2>&1; then
    fail 'KOReader ja aberto. Abra Sudoku pelo menu do KOReader ou feche-o antes.'
fi
mkdir "$plugin/launch.lock" 2>/dev/null || fail 'Sudoku ja esta sendo iniciado; se o Kindle desligou abruptamente, remova launch.lock.'
cleanup() {
    rm -f "$plugin/launch.request"
    rmdir "$plugin/launch.lock" 2>/dev/null || :
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '%s\n' "$target" > "$plugin/launch.request" || fail 'Nao foi possivel criar a solicitacao.'
sh "$ko_root/koreader.sh" --kual "$usb_root/documents" >> "$plugin/launcher.log" 2>&1
exit $?
