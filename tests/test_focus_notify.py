import importlib.util
import json
import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import call, patch

ROOT = Path(__file__).resolve().parents[1]


class FocusNotifyTests(unittest.TestCase):
    def setUp(self):
        environment = patch.dict(os.environ, {}, clear=True)
        environment.start()
        self.addCleanup(environment.stop)
        spec = importlib.util.spec_from_file_location(
            "focus_notify", ROOT / "config/herdr/plugins/focus-notify/focus_notify.py"
        )
        self.plugin = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.plugin)
        runner = patch.object(self.plugin, "run")
        self.run = runner.start()
        self.addCleanup(runner.stop)
        sleeper = patch.object(self.plugin.time, "sleep")
        sleeper.start()
        self.addCleanup(sleeper.stop)

    def response(self, data, status=0):
        return subprocess.CompletedProcess([], status, json.dumps(data), "")

    def test_niri_startup_terminal_is_active(self):
        os.environ.update(NIRI_SOCKET="/niri.sock", HYPRLAND_INSTANCE_SIGNATURE="old")
        self.run.return_value = self.response({"app_id": "wezterm.startup"})
        self.assertTrue(self.plugin.active_terminal())
        self.run.assert_called_once_with("niri", "msg", "--json", "focused-window", timeout=2)

    def test_niri_no_focus_and_invalid_responses(self):
        os.environ["NIRI_SOCKET"] = "/niri.sock"
        for data in (None, {"app_id": "zen"}, [], "invalid"):
            with self.subTest(data=data):
                self.run.return_value = self.response(data)
                self.assertFalse(self.plugin.active_terminal())

    def test_niri_desktop_never_falls_back_to_hyprland(self):
        os.environ.update(XDG_CURRENT_DESKTOP="other:NIRI", HYPRLAND_INSTANCE_SIGNATURE="old")
        self.assertIsNone(self.plugin.hyprland_env())
        self.run.assert_not_called()
        self.run.return_value = self.response(None, status=1)
        self.assertFalse(self.plugin.active_terminal())
        self.run.assert_called_once_with("niri", "msg", "--json", "focused-window", timeout=2)

    def test_niri_focus_prefers_focused_terminal(self):
        os.environ["NIRI_SOCKET"] = "/niri.sock"
        self.run.side_effect = [self.response(None), self.response([
            {"id": 2, "app_id": "wezterm.startup", "is_focused": False},
            {"id": 3, "app_id": "org.wezfurlong.wezterm", "is_focused": True},
        ]), self.response(None)]
        self.plugin.focus_pane("w1:p1")
        self.assertEqual(self.run.call_args_list, [
            call("herdr", "agent", "focus", "w1:p1"),
            call("niri", "msg", "--json", "windows", timeout=2),
            call("niri", "msg", "action", "focus-window", "--id", "3"),
        ])

    def test_niri_focus_finds_startup_terminal_from_browser(self):
        os.environ["NIRI_SOCKET"] = "/niri.sock"
        self.run.side_effect = [self.response(None), self.response([
            {"id": 8, "app_id": "zen", "is_focused": True},
            {"id": 0, "app_id": "wezterm.startup", "is_focused": False},
        ]), self.response(None)]
        self.plugin.focus_pane("w1:p1")
        self.run.assert_called_with("niri", "msg", "action", "focus-window", "--id", "0")

    def test_niri_missing_terminal_or_invalid_id_does_not_focus(self):
        os.environ["NIRI_SOCKET"] = "/niri.sock"
        for windows in ([], None, [{"app_id": "wezterm.startup", "id": "bad"}]):
            with self.subTest(windows=windows):
                self.run.reset_mock()
                self.run.side_effect = [self.response(None), self.response(windows)]
                self.plugin.focus_pane("w1:p1")
                self.assertEqual(self.run.call_count, 2)

    def test_hyprland_detection_preserved(self):
        self.run.side_effect = [
            self.response([{"instance": "old", "time": 1}, {"instance": "current", "time": 2}]),
            self.response({"class": "org.wezfurlong.wezterm"}),
        ]
        self.assertTrue(self.plugin.active_terminal())
        self.assertEqual(self.run.call_args.kwargs["env"]["HYPRLAND_INSTANCE_SIGNATURE"], "current")
        self.assertEqual(self.run.call_args.args, ("hyprctl", "activewindow", "-j"))

    def test_hyprland_focus_preserved(self):
        self.run.side_effect = [self.response(None), self.response([{"instance": "current"}]), self.response(None)]
        self.plugin.focus_pane("w1:p1")
        self.assertEqual(self.run.call_args.args[:2], ("hyprctl", "dispatch"))
        self.assertIn(self.plugin.TERMINAL_SELECTOR, self.run.call_args.args[2].replace('\\\\', '\\'))

    def test_agent_focus_failure_does_not_focus_compositor(self):
        os.environ["NIRI_SOCKET"] = "/niri.sock"
        self.run.return_value = self.response(None, status=1)
        self.plugin.focus_pane("w1:p1")
        self.run.assert_called_once_with("herdr", "agent", "focus", "w1:p1")


class FishSessionTests(unittest.TestCase):
    def test_session_environment(self):
        startup = (ROOT / "config/fish/config.fish").read_text().split("\nfish_add_path", 1)[0]
        cases = [
            ({"NIRI_SOCKET": "/niri.sock", "XDG_CURRENT_DESKTOP": "Hyprland"}, ""),
            ({"XDG_CURRENT_DESKTOP": "other:NIRI"}, ""),
            ({"XDG_CURRENT_DESKTOP": "Hyprland"}, "current"),
        ]
        for session, expected in cases:
            with self.subTest(session=session):
                environment = os.environ.copy()
                for key in ("NIRI_SOCKET", "XDG_CURRENT_DESKTOP", "HYPRLAND_INSTANCE_SIGNATURE"):
                    environment.pop(key, None)
                environment.update(session, HYPRLAND_INSTANCE_SIGNATURE="current")
                result = subprocess.run(
                    ["fish", "--no-config", "-c", startup + '\nprintf "%s" "$HYPRLAND_INSTANCE_SIGNATURE"'],
                    env=environment, text=True, capture_output=True, check=True,
                )
                self.assertEqual(result.stdout, expected)
                self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
