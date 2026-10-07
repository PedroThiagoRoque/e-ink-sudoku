#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p dist
rm -f dist/sudoku.koplugin.zip dist/kual-sudoku.zip
zip -qr dist/sudoku.koplugin.zip sudoku.koplugin
zip -qr dist/kual-sudoku.zip kual/sudoku
