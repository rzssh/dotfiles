import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "ai-workspace-picker"


class AiWorkspacePickerTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.profiles = self.root / "profiles"
        self.cwd = self.root / "project"
        self.log = self.root / "workspace.json"
        self.herdr_log = self.root / "herdr.json"
        self.input = self.root / "fzf-input"
        self.bin.mkdir()
        self.profiles.mkdir()
        self.cwd.mkdir()
        for profile in ("personal", "job-one", "job-two"):
            (self.profiles / profile).mkdir()
        self.executable(
            "herdr",
            '#!/usr/bin/env python3\nimport json, os, pathlib, sys\nif sys.argv[1:3] == ["notification", "show"]:\n pathlib.Path(os.environ["HERDR_LOG"]).write_text(json.dumps(sys.argv[1:]))\nelse:\n print(json.dumps({"result": {"pane": {"foreground_cwd": os.environ["PICKER_CWD"]}}}))\n',
        )
        self.executable(
            "fzf",
            '#!/usr/bin/env python3\nimport os, pathlib, sys\npathlib.Path(os.environ["FZF_INPUT"]).write_text(sys.stdin.read())\nchoice = os.environ.get("FZF_CHOICE")\nif choice:\n print(choice)\nelse:\n raise SystemExit(130)\n',
        )
        self.executable(
            "ai-workspace",
            '#!/usr/bin/env python3\nimport json, os, pathlib, sys\npathlib.Path(os.environ["WORKSPACE_LOG"]).write_text(json.dumps(sys.argv[1:]))\n',
        )

    def tearDown(self):
        self.temp.cleanup()

    def executable(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def invoke(self, choice="job-two"):
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "AI_PROFILE": "job-one",
            "AI_PROFILES_DIR": str(self.profiles),
            "FZF_CHOICE": choice,
            "FZF_INPUT": str(self.input),
            "HERDR_ACTIVE_PANE_ID": "w1:p2",
            "HERDR_BIN_PATH": str(self.bin / "herdr"),
            "HERDR_LOG": str(self.herdr_log),
            "HOME": str(self.root),
            "PATH": f'{self.bin}:{os.environ["PATH"]}',
            "PICKER_CWD": str(self.cwd),
            "WORKSPACE_LOG": str(self.log),
        }
        if not choice:
            env.pop("FZF_CHOICE")
        return subprocess.run([str(SCRIPT)], env=env, capture_output=True, text=True)

    def test_launches_selected_profile_at_source_pane_cwd(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.log.read_text()), ["job-two", str(self.cwd)])
        self.assertEqual(self.input.read_text().splitlines()[0], "job-one")
        self.assertNotIn("personal", self.input.read_text().splitlines())

    def test_cancel_does_not_create_workspace(self):
        result = self.invoke("")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.log.exists())

    def test_ignores_invalid_profile_names(self):
        (self.profiles / "bad profile").mkdir()
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("bad profile", self.input.read_text())

    def test_notifies_when_only_default_profile_exists(self):
        for profile in ("job-one", "job-two"):
            (self.profiles / profile).rmdir()
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.input.exists())
        self.assertFalse(self.log.exists())
        self.assertEqual(
            json.loads(self.herdr_log.read_text()),
            [
                "notification",
                "show",
                "No alternate AI profiles",
                "--body",
                "Add ~/.local/share/ai/profiles/<name>/env (directory 0700, file 0600)",
            ],
        )


if __name__ == "__main__":
    unittest.main()
