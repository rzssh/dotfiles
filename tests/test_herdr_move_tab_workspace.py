import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "herdr-move-tab-workspace"


class HerdrMoveTabWorkspaceTest(unittest.TestCase):
    def test_moves_every_pane_into_one_named_tab(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = root / "herdr"
            log = root / "calls"
            fake.write_text(
                """#!/usr/bin/env python3
import json
import os
import sys

args = sys.argv[1:]
with open(os.environ["HERDR_TEST_LOG"], "a") as stream:
    stream.write(json.dumps(args) + "\\n")
if args[:2] == ["workspace", "list"]:
    result = {"result": {"workspaces": [{"number": 2, "workspace_id": "w2"}]}}
elif args[:2] == ["tab", "get"]:
    result = {"result": {"tab": {"label": "named tab"}}}
elif args[:2] == ["pane", "layout"]:
    result = {"result": {"layout": {"focused_pane_id": "w1:p2", "zoomed": False, "panes": [{"pane_id": "w1:p1"}, {"pane_id": "w1:p2"}, {"pane_id": "w1:p3"}], "splits": [{"direction": "right"}]}}}
elif args[:2] == ["pane", "move"] and "--new-tab" in args:
    result = {"result": {"move_result": {"changed": True, "created_tab": {"tab_id": "w2:t4"}, "pane": {"pane_id": "w2:p4"}}}}
elif args[:2] == ["pane", "move"]:
    result = {"result": {"move_result": {"changed": True, "pane": {"pane_id": "new:" + args[2]}}}}
else:
    result = {"result": {}}
print(json.dumps(result))
"""
            )
            fake.chmod(0o755)
            env = {
                "HERDR_ACTIVE_PANE_ID": "w1:p2",
                "HERDR_ACTIVE_TAB_ID": "w1:t1",
                "HERDR_ACTIVE_WORKSPACE_ID": "w1",
                "HERDR_BIN_PATH": str(fake),
                "HERDR_TEST_LOG": str(log),
                "PATH": os.environ["PATH"],
            }

            result = subprocess.run([str(SCRIPT), "2"], env=env, capture_output=True, text=True)

            self.assertEqual(result.returncode, 0, result.stderr)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            moves = [call for call in calls if call[:2] == ["pane", "move"]]
            self.assertEqual([move[2] for move in moves], ["w1:p1", "w1:p3", "w1:p2"])
            self.assertIn("named tab", moves[0])
            self.assertIn("--new-tab", moves[0])
            self.assertNotIn("--tab", moves[0])
            self.assertTrue(all(move[move.index("--tab") + 1] == "w2:t4" for move in moves[1:]))
            self.assertIn("--focus", moves[-1])
            self.assertEqual(calls[-1], ["tab", "focus", "w2:t4"])


if __name__ == "__main__":
    unittest.main()
