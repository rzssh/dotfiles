#!/usr/bin/env python3
import fcntl
import json
import os
import socket
import sys
from pathlib import Path

SOURCE = f"plugin:{os.environ['HERDR_PLUGIN_ID']}"
STATE = Path(os.environ["HERDR_PLUGIN_STATE_DIR"]) / "mode"


def call(method, params):
    payload = {
        "id": "agent-view-mode",
        "method": method,
        "params": params,
    }
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(5)
        client.connect(os.environ["HERDR_SOCKET_PATH"])
        client.sendall(json.dumps(payload, separators=(",", ":")).encode() + b"\n")
        with client.makefile("r", encoding="utf-8") as stream:
            response = json.loads(stream.readline())
    if error := response.get("error"):
        raise RuntimeError(error["message"])


def apply(mode):
    if mode == "all":
        call("agent.view.clear", {"source": SOURCE})
        return
    call(
        "agent.view.set",
        {
            "source": SOURCE,
            "label": "current",
            "filter": {
                "op": "eq",
                "field": "workspace_id",
                "value": {"context": "current_workspace_id"},
            },
        },
    )


def main():
    STATE.parent.mkdir(parents=True, exist_ok=True)
    with STATE.with_suffix(".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            mode = STATE.read_text().strip()
        except OSError:
            mode = "current"
        if mode not in {"current", "all"}:
            mode = "current"
        if sys.argv[1:] == ["--cycle"]:
            mode = "all" if mode == "current" else "current"
        apply(mode)
        STATE.write_text(f"{mode}\n")


if __name__ == "__main__":
    main()
