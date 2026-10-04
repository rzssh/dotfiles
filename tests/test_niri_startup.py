import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG = (ROOT / "config/niri/config.kdl").read_text()
RULES = re.findall(r"^window-rule \{\n(.*?)^\}", CONFIG, re.M | re.S)


def matches(rule, app_id):
    return any(
        re.search(raw or normal, app_id)
        for raw, normal in re.findall(r'match app-id=(?:r#"([^"]+)"#|"([^"]+)")', rule)
    )


class NiriStartupTests(unittest.TestCase):
    def test_destinations_and_startup_focus(self):
        apps = {
            "wezterm.startup": "terminal",
            "org.telegram.desktop": "chat",
            "vesktop": "chat",
            "zen-beta": "browser",
            "chrome-music.youtube.com__-Default": "browser",
            "Mailspring": "chat",
        }
        for app_id, workspace in apps.items():
            with self.subTest(app_id=app_id):
                destinations = [
                    re.search(r'open-on-workspace "([^"]+)"', rule).group(1)
                    for rule in RULES
                    if "open-on-workspace" in rule and matches(rule, app_id)
                ]
                self.assertEqual(destinations, [workspace])
                if workspace != "terminal":
                    self.assertTrue(any(
                        matches(rule, app_id) and "at-startup=true" in rule
                        and "open-focused false" in rule for rule in RULES
                    ))

    def test_dms_blur_uses_client_regions(self):
        layers = re.findall(r"^layer-rule \{\n(.*?)^\}", CONFIG, re.M | re.S)
        for namespace in ("dms:notification-popup", "dms:niri-overview-spotlight", "dms:screenshot"):
            for rule in layers:
                patterns = re.findall(r'match namespace="([^"]+)"', rule)
                if any(re.search(pattern, namespace) for pattern in patterns):
                    self.assertNotRegex(rule, r"\bblur\s+true")
        self.assertRegex(CONFIG, r"Mod\+O\b[^\n]*\{ toggle-overview; \}")

    def test_telegram_desktop_filename(self):
        desktop = (ROOT / "home/desktop.nix").read_text()
        entry = re.search(r'xdg.desktopEntries\."([^"]*telegram[^"]*)" =', desktop).group(1)
        self.assertIn(entry + ".desktop", (ROOT / "bin/niri-startup").read_text())
        self.assertIn(f'gtk-launch {entry}.desktop', (ROOT / "config/hypr/hyprland.lua").read_text())

    def test_named_workspaces(self):
        workspaces = ("terminal", "browser", "chat")
        self.assertEqual(re.findall(r'^workspace "([^"]+)"', CONFIG, re.M), list(workspaces))
        for index, workspace in enumerate(workspaces, 1):
            self.assertIn(f'Mod+{index} {{ focus-workspace "{workspace}"; }}', CONFIG)
            self.assertIn(f'Mod+Shift+{index} {{ move-window-to-workspace "{workspace}"; }}', CONFIG)
        for index in range(4, 10):
            self.assertIn(f'Mod+{index} {{ focus-workspace {index}; }}', CONFIG)
            self.assertIn(f'Mod+Shift+{index} {{ move-window-to-workspace {index}; }}', CONFIG)

    def test_maximize_preserves_gaps(self):
        self.assertIn('Mod+F repeat=false { spawn-sh "niri msg action maximize-column && niri msg action set-window-height 100%"; }', CONFIG)
        self.assertIn('Mod+Shift+F { fullscreen-window; }', CONFIG)

    def test_nav_shortcuts(self):
        binds = set(re.findall(r'^    (\S+)(?: [^\n{]+)? \{', CONFIG, re.M))
        expected = {
            "XF86Launch7", "XF86Tools", "XF86Launch5", "XF86Launch6",
            "Ctrl+XF86Tools", "Alt+XF86Tools", "Mod+Ctrl+F10",
            "Mod+Page_Up", "Mod+Page_Down", "Mod+Shift+Page_Up", "Mod+Shift+Page_Down",
            "Mod+P", "Mod+Shift+P", "Mod+Ctrl+P", "Mod+Alt+P", "Mod+R",
            "Mod+F", "Mod+Shift+F", "Mod+Ctrl+F", "Mod+Alt+F", "Mod+Tab",
            "Mod+F5", "Mod+F6", "Mod+F7", "Mod+F8", "Mod+F9", "Mod+F11", "Mod+F12",
        }
        for function in range(1, 5):
            expected.update(f"Mod+{modifier}F{function}" for modifier in ("", "Shift+", "Ctrl+", "Alt+"))
        self.assertFalse(expected - binds, expected - binds)
        self.assertRegex(CONFIG, r'XF86Launch7\b[^\n]*\{ toggle-overview; \}')
        for key in ("XF86Tools", "XF86Launch5", "XF86Launch6", "Ctrl+XF86Tools", "Alt+XF86Tools"):
            self.assertRegex(CONFIG, rf'(?m)^    {re.escape(key)}\b[^\n]*\{{ spawn "wl-kbptr"')

    def test_global_opacity_toggle(self):
        self.assertIn('Mod+Ctrl+F10 repeat=false { spawn "bash" "/home/razen/projects/dotfiles/bin/niri-toggle-opacity"; }', CONFIG)
        self.assertIn('include optional=true "~/.cache/niri-opacity.kdl"', CONFIG)
        self.assertNotIn('toggle-window-rule-opacity', CONFIG)
        with tempfile.TemporaryDirectory() as directory:
            override = Path(directory) / ".cache/niri-opacity.kdl"
            for enabled in (False, True):
                subprocess.run(
                    ["bash", str(ROOT / "bin/niri-toggle-opacity")],
                    env={**os.environ, "HOME": directory}, check=True,
                )
                self.assertEqual(override.exists(), not enabled)
                if not enabled:
                    self.assertEqual(override.read_text(), 'window-rule {\n    match is-active=false\n    opacity 1.0\n}\n')

    def test_startup_arranges_windows_after_apps_open(self):
        for missing_mail in (False, True):
            with self.subTest(missing_mail=missing_mail), tempfile.TemporaryDirectory() as directory:
                directory = Path(directory)
                log = directory / "commands"
                windows = [
                    {"id": index, "app_id": app_id, "is_floating": False, "title": "Main"}
                    for index, app_id in enumerate((
                        "Mailspring", "chrome-music.youtube.com__-Default", "org.telegram.desktop",
                        "wezterm.startup", "vesktop", "zen-beta",
                    ), 1)
                    if not (missing_mail and app_id == "Mailspring")
                ]
                windows.insert(0, {"id": 0, "app_id": "org.telegram.desktop", "is_floating": False, "title": "Media viewer"})
                (directory / "windows.json").write_text(json.dumps(windows))
                for command in ("wezterm", "gtk-launch", "sleep"):
                    path = directory / command
                    path.write_text('#!/usr/bin/env bash\nprintf "%s %s\\n" "$(basename "$0")" "$*" >> "$COMMAND_LOG"\n')
                    path.chmod(0o755)
                niri = directory / "niri"
                niri.write_text(
                    '#!/usr/bin/env python3\n'
                    'import os, sys\n'
                    'from pathlib import Path\n'
                    'root = Path(__file__).parent\n'
                    'args = " ".join(sys.argv[1:])\n'
                    'with open(os.environ["COMMAND_LOG"], "a") as log:\n'
                    '    log.write("niri " + args + "\\n")\n'
                    'if args == "msg -j windows":\n'
                    '    count = root / "polls"\n'
                    '    polls = int(count.read_text()) if count.exists() else 0\n'
                    '    count.write_text(str(polls + 1))\n'
                    '    print("[]" if polls == 0 else (root / "windows.json").read_text())\n'
                )
                niri.chmod(0o755)
                result = subprocess.run(
                    ["bash", str(ROOT / "bin/niri-startup")],
                    env={**os.environ, "PATH": f"{directory}:{os.environ['PATH']}", "COMMAND_LOG": str(log)},
                    capture_output=True, text=True, timeout=15,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                commands = log.read_text().splitlines()
                self.assertCountEqual([line for line in commands if line.startswith(("wezterm ", "gtk-launch "))], [
                    "wezterm start --class=wezterm.startup",
                    "gtk-launch org.telegram.desktop.desktop", "gtk-launch vesktop",
                    "gtk-launch zen-beta", "gtk-launch youtube-music-webapp", "gtk-launch mailspring",
                ])
                self.assertEqual(int((directory / "polls").read_text()), 60 if missing_mail else 2)
                ids = [3, 5, 2, 6, 4] if missing_mail else [1, 3, 5, 2, 6, 4]
                self.assertEqual([line for line in commands if line.startswith("niri msg action ")], [
                    command for id in ids for command in (
                        f"niri msg action focus-window --id {id}", "niri msg action move-column-to-first",
                    )
                ])


if __name__ == "__main__":
    unittest.main()
