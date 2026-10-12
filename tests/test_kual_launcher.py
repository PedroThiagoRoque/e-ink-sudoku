"""Verifica o handoff KUAL -> KOReader sem executar software do Kindle."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "kual/sudoku/launch.sh"
CONFIG = ROOT / "kual/sudoku/config.xml"


class KualLauncherTest(unittest.TestCase):
    def test_kual_manifest_declares_the_json_menu(self):
        root = ET.parse(CONFIG).getroot()
        menu = root.find("./menus/menu")
        self.assertIsNotNone(menu)
        self.assertEqual(menu.get("type"), "json")
        self.assertEqual(menu.get("dynamic"), "true")
        self.assertEqual(menu.text, "menu.json")

    def run_launcher(self, root, *args):
        return subprocess.run(
            ["sh", str(SCRIPT), *args],
            env={**os.environ, "SUDOKU_USB_ROOT": str(root)},
            capture_output=True,
        )

    def test_missing_koreader_fails_without_creating_request(self):
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            result = self.run_launcher(root)
            self.assertEqual(result.returncode, 1)
            self.assertIn(b"KOReader nao encontrado", result.stderr)
            self.assertFalse((root / "koreader/plugins/sudoku.koplugin/launch.request").exists())

    def test_launcher_hands_menu_request_to_koreader_and_cleans_up(self):
        with tempfile.TemporaryDirectory() as temporary_root:
            root = Path(temporary_root)
            plugin = root / "koreader/plugins/sudoku.koplugin"
            plugin.mkdir(parents=True)
            (plugin / "main.lua").write_text("-- fixture")
            (root / "koreader/luajit").touch()
            (root / "koreader/koreader.sh").write_text(
                "#!/bin/sh\n"
                '[ "$1" = "--kual" ] || exit 8\n'
                '[ "$2" = "$SUDOKU_USB_ROOT/documents" ] || exit 9\n'
                '[ "$(cat "$SUDOKU_USB_ROOT/koreader/plugins/sudoku.koplugin/launch.request")" = "menu" ] || exit 10\n'
                "exit 7\n"
            )
            result = self.run_launcher(root, "menu")
            self.assertEqual(result.returncode, 7, result.stderr.decode())
            self.assertFalse((plugin / "launch.request").exists())
            self.assertFalse((plugin / "launch.lock").exists())

    def test_invalid_target_fails(self):
        with tempfile.TemporaryDirectory() as temporary_root:
            result = self.run_launcher(Path(temporary_root), "invalid")
            self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
