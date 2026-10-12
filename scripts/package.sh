#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p dist
rm -f dist/sudoku.koplugin.zip dist/kual-sudoku.zip
zip -qr dist/sudoku.koplugin.zip sudoku.koplugin
package_dir=$(mktemp -d)
trap 'rm -rf "$package_dir"' EXIT
mkdir -p "$package_dir/extensions"
cp -R kual/sudoku "$package_dir/extensions/sudoku"
(cd "$package_dir" && zip -qr "$OLDPWD/dist/kual-sudoku.zip" extensions)
