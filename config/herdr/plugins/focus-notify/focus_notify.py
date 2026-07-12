#!/usr/bin/env python3
import json
import os
import pathlib
import subprocess
import sys
import time

KINDS = {"done": "finished", "blocked": "needs input"}
TERMINAL_CLASS = os.environ.get("HERDR_TERMINAL_CLASS", "com.mitchellh.ghostty")
TERMINAL_SELECTOR = os.environ.get("HERDR_WINDOW_SELECTOR", f"class:{TERMINAL_CLASS}")


def run(*args, timeout=5):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except Exception:
        return None


def herdr_bin():
    return os.environ.get("HERDR_BIN_PATH") or "herdr"


def state_dir():
    root = os.environ.get("HERDR_PLUGIN_STATE_DIR") or "/tmp/herdr-focus-notify"
    path = pathlib.Path(root)
    path.mkdir(parents=True, exist_ok=True)
    return path


def load_state():
    path = state_dir() / "state.json"
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def save_state(state):
    path = state_dir() / "state.json"
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, separators=(",", ":")))
    tmp.replace(path)


def event_data():
    raw = os.environ.get("HERDR_PLUGIN_EVENT_JSON") or "{}"
    try:
        event = json.loads(raw)
    except Exception:
        return {}
    return event.get("data") or event


def panes():
    r = run(herdr_bin(), "pane", "list")
    if not r or r.returncode != 0:
        return []
    try:
        return json.loads(r.stdout)["result"]["panes"]
    except Exception:
        return []


def pane_info(pane_id):
    for pane in panes():
        if pane.get("pane_id") == pane_id:
            return pane
    return {}


def basename(path):
    clean = (path or "").rstrip("/")
    return clean.rsplit("/", 1)[-1] or clean or "agent"


def active_terminal():
    r = run("hyprctl", "activewindow", "-j", timeout=2)
    if not r or r.returncode != 0:
        return False
    try:
        return json.loads(r.stdout or "{}").get("class") == TERMINAL_CLASS
    except Exception:
        return False


def visible(pane):
    return bool(pane.get("focused")) and active_terminal()


def focus_pane(pane_id):
    run(herdr_bin(), "agent", "focus", pane_id)
    run("hyprctl", "dispatch", f'hl.dsp.focus({{ window = "{TERMINAL_SELECTOR}" }})')


def wait_notification(title, pane_id):
    r = run("notify-send", "-a", "herdr", "-e", "-t", "8000", "-A", "default=Open", title, timeout=30)
    if r and (r.stdout or "").strip() == "default":
        focus_pane(pane_id)


def spawn_notification(title, pane_id):
    subprocess.Popen(
        [sys.executable, __file__, "--wait", title, pane_id],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
        env=os.environ.copy(),
    )


def notify_for(pane_id, status):
    pane = pane_info(pane_id)
    if visible(pane):
        return
    title = f"{basename(pane.get('cwd'))} — {KINDS.get(status, status)}"
    spawn_notification(title, pane_id)


def handle_event():
    data = event_data()
    pane_id = data.get("pane_id") or os.environ.get("HERDR_PANE_ID")
    status = data.get("agent_status") or data.get("status")
    if not pane_id or not status:
        return

    state = load_state()
    pane_state = state.get(pane_id, {})
    prev = pane_state.get("status")
    kind = "done" if prev == "working" and status == "idle" else status
    now = time.time()
    last_key = f"last_{kind}"
    pane_state["status"] = status
    state[pane_id] = pane_state
    save_state(state)

    if kind not in KINDS:
        return
    if now - float(pane_state.get(last_key, 0)) < 10:
        return

    pane_state[last_key] = now
    save_state(state)
    notify_for(pane_id, kind)


def test():
    pane_id = os.environ.get("HERDR_PANE_ID")
    if not pane_id:
        current = panes()
        pane_id = current[0].get("pane_id") if current else "w1:p1"
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
