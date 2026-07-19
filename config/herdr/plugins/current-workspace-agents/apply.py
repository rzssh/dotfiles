#!/usr/bin/env python3
import json
import os
import socket

request = {
    "id": "current-workspace-agents",
    "method": "agent.view.set",
    "params": {
        "source": f"plugin:{os.environ['HERDR_PLUGIN_ID']}",
        "label": "current",
        "filter": {
            "op": "eq",
            "field": "workspace_id",
            "value": {"context": "current_workspace_id"},
        },
    },
}

with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
    client.settimeout(5)
    client.connect(os.environ["HERDR_SOCKET_PATH"])
    client.sendall(json.dumps(request, separators=(",", ":")).encode() + b"\n")
    with client.makefile("r", encoding="utf-8") as stream:
        response = json.loads(stream.readline())

if error := response.get("error"):
    raise RuntimeError(error["message"])
