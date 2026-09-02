#!/usr/bin/env bash
# Print every fault this demo ships, and what each one can be set to.
set -euo pipefail
NS="${NS:-otel-demo}"
kubectl get cm -n "$NS" "${CM:-flagd-config}" -o json | python3 -c '
import json, sys
data = json.load(sys.stdin)["data"]
key = next(k for k in data if "flag" in k.lower() or k.endswith(".json"))
for name, f in sorted(json.loads(data[key])["flags"].items()):
    now = f.get("defaultVariant")
    print(f"{name:32} now={now:8} variants={', '.join(map(str, f['variants']))}")
'
