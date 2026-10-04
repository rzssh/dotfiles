import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS = ROOT.parent / "agents"


class UpdateTest(unittest.TestCase):
    def run_update(self, failure=""):
        with tempfile.TemporaryDirectory(dir=ROOT / "tests") as directory:
            home = Path(directory)
            for name, source in [("dotfiles", ROOT), ("agents", AGENTS)]:
                target = home / "projects" / name / "bin"
                target.mkdir(parents=True)
                (target / "update").write_text((source / "bin/update").read_text())
            (home / "projects/agents/bin/update-pi").write_text(
                'printf "pi-update\\n" >> "$UPDATE_LOG"\n'
            )
            commands = home / "commands"
            commands.mkdir()
            for name in ["nix", "nix-update", "python3", "codex", "claude"]:
                command = (
                    home / ".local/bin" if name in ["codex", "claude"] else commands
                ) / name
                command.parent.mkdir(parents=True, exist_ok=True)
                command.write_text(
                    '#!/usr/bin/env bash\nprintf "%s %s\\n" "${0##*/}" "$*" >> "$UPDATE_LOG"\n[[ "$*" != "$UPDATE_FAIL" ]]\n'
                )
                command.chmod(0o755)
            log = home / "log"
            environment = dict(
                os.environ, HOME=str(home), UPDATE_LOG=str(log), UPDATE_FAIL=failure
            )
            environment["PATH"] = str(commands) + os.pathsep + environment["PATH"]
            result = subprocess.run(
                ["bash", str(home / "projects/dotfiles/bin/update")],
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            return result, log.read_text().splitlines()

    def test_full_update_covers_lightweight_tools_without_activation(self):
        result, commands = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        for package in [
            "chrome-devtools-axi",
            "gh-axi",
            "lavish-axi",
            "quota-axi",
            "tasks-axi",
            "no-mistakes",
            "chrome-devtools-mcp",
            "hyprwhspr",
            "flectar-mail",
            "qmk-hid-host",
            "zmk-vim-mode",
        ]:
            self.assertTrue(
                any(
                    line.startswith("nix-update ") and line.endswith(" " + package)
                    for line in commands
                ),
                package,
            )
        self.assertIn("pi-update", commands)
        self.assertEqual(commands.count("nix flake update --refresh"), 2)
        self.assertEqual(commands[-2:], ["codex update", "claude update"])
        self.assertFalse(
            any(
                line.startswith(("nix build", "nix flake check", "nix profile"))
                or line == "python3 tests/test_update.py"
                for line in commands
            )
        )
        self.assertFalse(
            any(
                "llama" in line or "cuda" in line or "bambu" in line or "switch" in line
                for line in commands
            )
        )

    def test_failed_update_stops_before_client_updates(self):
        result, commands = self.run_update("--flake no-mistakes")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(commands[-1], "nix-update --flake no-mistakes")
        self.assertFalse(
            any(line in ["codex update", "claude update"] for line in commands)
        )


if __name__ == "__main__":
    unittest.main()
