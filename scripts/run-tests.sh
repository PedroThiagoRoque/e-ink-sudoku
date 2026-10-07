#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
for test_file in sudoku.koplugin/tests/test_*.lua; do
    lua "$test_file"
done

