#!/usr/bin/env python3
"""Cliente MCP stdio mínimo. Uso:
  mcp_call.py <comando servidor...> -- list
  mcp_call.py <comando servidor...> -- call <tool> '<json args>'
Imprime la respuesta de tools/list (nombres) o el texto de tools/call.
"""
import json
import subprocess
import sys

argv = sys.argv[1:]
if "--" not in argv:
    sys.exit(__doc__)
sep = argv.index("--")
server, action = argv[:sep], argv[sep + 1:]
msgs = [
    {"jsonrpc": "2.0", "id": 1, "method": "initialize",
     "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "driver", "version": "1"}}},
    {"jsonrpc": "2.0", "method": "notifications/initialized"},
]
if action[:1] == ["list"]:
    msgs.append({"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
elif action[:1] == ["call"] and len(action) >= 2:
    args = json.loads(action[2]) if len(action) > 2 else {}
    msgs.append({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": action[1], "arguments": args}})
else:
    sys.exit(__doc__)
p = subprocess.run(server, input="".join(json.dumps(m) + "\n" for m in msgs),
                   capture_output=True, text=True, timeout=60)
for line in p.stdout.splitlines():
    r = json.loads(line)
    if r.get("id") != 2:
        continue
    if "error" in r:
        print("ERROR:", r["error"]); sys.exit(1)
    res = r["result"]
    if "tools" in res:
        names = sorted(t["name"] for t in res["tools"])
        print(len(names), "tools:", " ".join(names))
    else:
        print(("ERROR: " if res.get("isError") else "") + res["content"][0]["text"])
        sys.exit(1 if res.get("isError") else 0)
