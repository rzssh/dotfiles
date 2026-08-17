#!/usr/bin/env python3
import json
import os
import pathlib
import re
import signal
import subprocess
import sys
import time

KINDS = {"done": "finished", "blocked": "needs input"}
terminal_classes = os.environ.get("HERDR_TERMINAL_CLASSES") or os.environ.get("HERDR_TERMINAL_CLASS")
TERMINAL_CLASSES = set(filter(None, (terminal_classes or "org.wezfurlong.wezterm").split(",")))
terminal_pattern = "|".join(re.escape(name) for name in TERMINAL_CLASSES)
TERMINAL_SELECTOR = os.environ.get("HERDR_WINDOW_SELECTOR", f"class:^({terminal_pattern})$")


def run(
    *args: str,
    timeout: float | None = 5,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout, env=env)
    except Exception:
        return None


def herdr_bin():
    return os.environ.get("HERDR_BIN_PATH") or "herdr"


def json_env(name):
    try:
        return json.loads(os.environ.get(name) or "{}")
    except Exception:
        return {}


def event_data():
    event = json_env("HERDR_PLUGIN_EVENT_JSON")
    return event.get("data") or event


def agent_info(pane_id):
    result = run(herdr_bin(), "agent", "get", pane_id)
    if not result or result.returncode != 0:
        return {}
    try:
        return json.loads(result.stdout)["result"]["agent"]
    except Exception:
        return {}


def basename(path):
    clean = (path or "").rstrip("/")
    return clean.rsplit("/", 1)[-1] or clean or "agent"


def hyprland_env():
    result = run("hyprctl", "instances", "-j", timeout=2)
    if not result or result.returncode != 0:
        return None
    try:
        instance = max(json.loads(result.stdout), key=lambda item: item.get("time", 0))["instance"]
    except Exception:
        return None
    env = os.environ.copy()
    env["HYPRLAND_INSTANCE_SIGNATURE"] = instance
    return env


def active_terminal():
    env = hyprland_env()
    if not env:
        return False
    result = run("hyprctl", "activewindow", "-j", timeout=2, env=env)
    if not result or result.returncode != 0:
        return False
    try:
        return json.loads(result.stdout or "{}").get("class") in TERMINAL_CLASSES
    except Exception:
        return False


def focus_pane(pane_id):
    result = run(herdr_bin(), "agent", "focus", pane_id)
    if not result or result.returncode != 0:
        return
    time.sleep(0.2)
    env = hyprland_env()
    if env:
        run(
            "hyprctl",
            "dispatch",
            f"hl.dsp.focus({{ window = {json.dumps(TERMINAL_SELECTOR)} }})",
            env=env,
        )


def dms_pid():
    result = run(
        "systemctl",
        "--user",
        "show",
        "--property=MainPID",
        "--value",
        "dms.service",
    )
    try:
        return int(result.stdout)
    except (AttributeError, TypeError, ValueError):
        return 0


def stop_notification(pane_id):
    script = os.path.realpath(__file__)
    for entry in pathlib.Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            args = (entry / "cmdline").read_bytes().rstrip(b"\0").split(b"\0")
            pid = int(entry.name)
            if (
                len(args) == 5
                and os.path.realpath(os.fsdecode(args[1])) == script
                and args[2] == b"--wait"
                and os.fsdecode(args[4]) == pane_id
                and os.getpgid(pid) == pid
            ):
                os.killpg(pid, signal.SIGTERM)
        except (OSError, UnicodeError):
            pass


def wait_notification(title, pane_id):
    server_pid = dms_pid()
    if not server_pid:
        return
    process = subprocess.Popen(
        ["notify-send", "-a", "herdr", "-A", "default=Open", title],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    while True:
        try:
            stdout, _ = process.communicate(timeout=1)
            break
        except subprocess.TimeoutExpired:
            if not pathlib.Path(f"/proc/{server_pid}").exists():
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                return
    if stdout.strip() == "default":
        focus_pane(pane_id)


def spawn_notification(title, pane_id):
    stop_notification(pane_id)
    subprocess.Popen(
        [sys.executable, __file__, "--wait", title, pane_id],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        env=os.environ.copy(),
    )


def notify_for(pane_id, status):
    info = agent_info(pane_id)
    if info.get("focused") and active_terminal():
        return
    context = json_env("HERDR_PLUGIN_CONTEXT_JSON")
    cwd = info.get("cwd") or context.get("focused_pane_cwd")
    spawn_notification(f"{basename(cwd)} — {KINDS[status]}", pane_id)


def handle_event():
    data = event_data()
    pane_id = data.get("pane_id") or os.environ.get("HERDR_PANE_ID")
    status = data.get("agent_status") or data.get("status")
    if pane_id and status in KINDS:
        notify_for(pane_id, status)


def test():
    pane_id = os.environ.get("HERDR_PANE_ID") or "w1:p1"
    spawn_notification("herdr — test", pane_id)


def main():
    if sys.argv[1:2] == ["--wait"]:
        wait_notification(sys.argv[2], sys.argv[3])
    elif sys.argv[1:2] == ["--test"]:
        test()
    else:
        handle_event()


if __name__ == "__main__":
    main()
