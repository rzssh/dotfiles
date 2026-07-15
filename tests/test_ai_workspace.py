import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "ai-workspace"


class AiWorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.cwd = self.root / "project"
        self.log = self.root / "herdr.json"
        self.bin.mkdir()
        self.cwd.mkdir()
        self.executable("ai-run", "#!/bin/sh\nexit 0\n")
        self.executable(
            "herdr",
            '#!/usr/bin/env python3\nimport json, os, pathlib, sys\npathlib.Path(os.environ["HERDR_LOG"]).write_text(json.dumps(sys.argv[1:]))\n',
        )

    def tearDown(self):
        self.temp.cleanup()

    def executable(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def invoke(self, profile=None):
        command = [str(SCRIPT)]
        if profile:
            command.extend([profile, str(self.cwd)])
        env = {
            "AI_DEFAULT_PROFILE": "personal",
            "HERDR_LOG": str(self.log),
            "PATH": f'{self.bin}:{os.environ["PATH"]}',
        }
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


if __name__ == "__main__":
    unittest.main()
