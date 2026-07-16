import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "herdr-jj-workspace"


class HerdrJjWorkspaceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.repo = self.root / "repo"
        self.log = self.root / "herdr.json"
        self.bin.mkdir()
        self.repo.mkdir()
        self.executable(
            "herdr",
            '#!/usr/bin/env python3\nimport json, os, pathlib, sys\nargs = sys.argv[1:]\nif args == ["pane", "list"]:\n print(json.dumps({"result": {"panes": [{"focused": True, "foreground_cwd": os.environ["TEST_REPO"], "workspace_id": "w9"}]}}))\nelif args[:3] == ["plugin", "pane", "open"]:\n pathlib.Path(os.environ["HERDR_LOG"]).write_text(json.dumps(args))\n',
        )
        self.executable(
            "jj",
            '#!/usr/bin/env python3\nimport os\nprint(os.environ["TEST_REPO"])\n',
        )
        self.executable(
            "ai-workspace",
            '#!/usr/bin/env python3\nimport os, sys\nassert sys.argv[1:] == ["--current-profile"]\nassert "AI_PROFILE" not in os.environ\nassert os.environ["HERDR_WORKSPACE_ID"] == "w9"\nprint("job-one")\n',
        )

    def tearDown(self):
        self.temp.cleanup()

    def executable(self, name, body):
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def test_workspace_wizard_receives_focused_workspace_profile(self):
        result = subprocess.run(
            [str(SCRIPT), "workspace"],
            env={
                "AI_PROFILE": "stale",
                "HERDR_LOG": str(self.log),
                "PATH": f'{self.bin}:{os.environ["PATH"]}',
                "TEST_REPO": str(self.repo),
            },
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        args = json.loads(self.log.read_text())
        self.assertIn("AI_PROFILE=job-one", args)


if __name__ == "__main__":
    unittest.main()
