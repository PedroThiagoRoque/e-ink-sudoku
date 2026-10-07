#!/usr/bin/env sh
# KUAL executa este arquivo no diretório da extensão.
# O jogo é aberto pelo menu do KOReader para evitar iniciar uma segunda instância.
if pgrep -f "koreader" >/dev/null 2>&1; then
    exit 0
fi
if [ -x /mnt/us/koreader/koreader.sh ]; then
    /mnt/us/koreader/koreader.sh >/tmp/koreader-sudoku-launch.log 2>&1 &
fi
