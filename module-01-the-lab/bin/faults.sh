#!/usr/bin/env bash
# Print every fault this demo ships, and what each one can be set to.
set -euo pipefail

# ⛔ THESE SCRIPTS NEED python3 AND NOTHING ELSE CHECKS FOR IT. On a Mac with no Xcode command
# line tools there is no python3, and `make leak` is the central act of module 1.
command -v python3 >/dev/null || { echo "python3 is not installed. On a Mac: xcode-select --install"; exit 2; }
NS="${NS:-otel-demo}"
kubectl get cm -n "$NS" "${CM:-flagd-config}" -o json | python3 -c '
import json, sys
data = json.load(sys.stdin)["data"]
key = next(k for k in data if "flag" in k.lower() or k.endswith(".json"))
for name, f in sorted(json.loads(data[key])["flags"].items()):
    now = f.get("defaultVariant")
    print(f"{name:32} now={now:8} variants={', '.join(map(str, f['variants']))}")
'
