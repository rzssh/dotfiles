import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "ai-workspace"
FISH_CONFIG = Path(__file__).parents[1] / "config" / "fish" / "conf.d" / "ai-run.fish"


class AiWorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.cwd = self.root / "project"
        self.log = self.root / "herdr.json"
        self.bin.mkdir()
        self.cwd.mkdir()
        self.executable(
            "ai-run",
            '#!/usr/bin/env python3\nimport os, sys\nif sys.argv[1:] == ["--profile-keys"]:\n print("AI_PROFILE\\nAI_PROFILE_LOADED\\nPERSONAL_ONLY_SECRET\\nPROFILE_SECRET")\n raise SystemExit\nprofile = sys.argv[1] if sys.argv[1] != "--" else os.environ.get("AI_PROFILE", "personal")\nif sys.argv[-2:] == ["env", "-0"]:\n os.write(1, f"AI_PROFILE={profile}\\0PROFILE_SECRET={profile}-secret\\0PATH={os.environ[\'PATH\']}\\0".encode())\n',
        )
        self.executable(
            "herdr",
            '#!/usr/bin/env python3\nimport json, os, pathlib, sys\nif "PERSONAL_ONLY_SECRET" in os.environ:\n raise SystemExit(3)\npathlib.Path(os.environ["HOME"], "herdr.json").write_text(json.dumps(sys.argv[1:]))\nprint(json.dumps({"result": {"workspace": {"workspace_id": "w9"}}}))\n',
        )

    def tearDown(self):
        self.temp.cleanup()

    def executable(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def invoke(self, profile=None, current=None):
        command = [str(SCRIPT)]
        if profile:
            command.extend([profile, str(self.cwd)])
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "HERDR_SOCKET_PATH": str(self.root / "herdr.sock"),
            "HOME": str(self.root),
            "PATH": f'{self.bin}:{SCRIPT.parent}:{os.environ["PATH"]}',
            "PERSONAL_ONLY_SECRET": "must-not-leak",
        }
        if current:
            env["AI_PROFILE"] = current
        return subprocess.run(command, cwd=self.cwd, env=env, capture_output=True, text=True)

    def test_default_profile_uses_native_label(self):
        result = self.invoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(self.log.read_text()),
            [
                "workspace",
                "create",
                "--cwd",
                str(self.cwd),
                "--env",
                "AI_PROFILE=personal",
                "--focus",
            ],
        )

    def test_alternate_profile_gets_visible_label(self):
        result = self.invoke("job-one")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(self.log.read_text()),
            [
                "workspace",
                "create",
                "--cwd",
                str(self.cwd),
                "--env",
                "AI_PROFILE=job-one",
                "--label",
                "project [job-one]",
                "--focus",
            ],
        )

    def test_current_profile_is_default_for_another_workspace(self):
        result = self.invoke(current="job-one")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(self.log.read_text()),
            [
                "workspace",
                "create",
                "--cwd",
                str(self.cwd),
                "--env",
                "AI_PROFILE=job-one",
                "--label",
                "project [job-one]",
                "--focus",
            ],
        )

    def test_new_pane_shell_loads_bound_profile(self):
        result = self.invoke("job-one")
        self.assertEqual(result.returncode, 0, result.stderr)
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "HERDR_ENV": "1",
            "HERDR_SOCKET_PATH": str(self.root / "herdr.sock"),
            "HERDR_WORKSPACE_ID": "w9",
            "HOME": str(self.root),
            "PATH": f'{self.bin}:{SCRIPT.parent}:{os.environ["PATH"]}',
            "PERSONAL_ONLY_SECRET": "must-not-leak",
        }
        loaded = subprocess.run(
            [
                "fish",
                "--no-config",
                "-c",
                f'source "{FISH_CONFIG}"; printf "%s\\n" "$AI_PROFILE" "$PROFILE_SECRET" "$AI_PROFILE_LOADED"; if set -q PERSONAL_ONLY_SECRET; echo leaked; else; echo clean; end',
            ],
            env=env,
            capture_output=True,
            text=True,
        )
        self.assertEqual(loaded.returncode, 0, loaded.stderr)
        self.assertEqual(
            loaded.stdout.splitlines(), ["job-one", "job-one-secret", "1", "clean"]
        )

    def test_native_workspace_keeps_initial_profile_for_later_panes(self):
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "AI_PROFILE": "job-one",
            "HERDR_ENV": "1",
            "HERDR_SOCKET_PATH": str(self.root / "herdr.sock"),
            "HERDR_WORKSPACE_ID": "native-1",
            "HOME": str(self.root),
            "PATH": f'{self.bin}:{SCRIPT.parent}:{os.environ["PATH"]}',
        }
        command = [
            "fish",
            "--no-config",
            "-c",
            f'source "{FISH_CONFIG}"; printf "%s\\n" "$AI_PROFILE" "$PROFILE_SECRET"',
        ]
        first = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(first.stdout.splitlines(), ["job-one", "job-one-secret"])

        env.pop("AI_PROFILE")
        second = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(second.stdout.splitlines(), ["job-one", "job-one-secret"])

if __name__ == "__main__":
    unittest.main()
