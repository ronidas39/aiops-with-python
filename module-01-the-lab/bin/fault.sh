#!/usr/bin/env bash
# Turn one of the demo's built-in faults on or off.
#
#   ./bin/fault.sh emailMemoryLeak 10000x     # fast: OOMKilled in about a minute
#   ./bin/fault.sh emailMemoryLeak 100x       # slow: a climb you can watch for half an hour
#   ./bin/fault.sh emailMemoryLeak off        # back to normal
#
# ⛔ THE VARIANT NAME IS NOT A BOOLEAN. The variants are off, 1x, 10x, 100x, 1000x, 10000x.
# Setting this flag to "on" is accepted without complaint and does nothing at all. I lost
# twenty two minutes watching flat memory before I worked that out, which is why this script
# checks the name against the flag's own variant list before it writes anything.
set -euo pipefail

# ⛔ THESE SCRIPTS NEED python3 AND NOTHING ELSE CHECKS FOR IT. On a Mac with no Xcode command
# line tools there is no python3, and `make leak` is the central act of module 1.
command -v python3 >/dev/null || { echo "python3 is not installed. On a Mac: xcode-select --install"; exit 2; }

FLAG="${1:?usage: fault.sh <flagName> <variant>}"
WANT="${2:?usage: fault.sh <flagName> <variant>}"
NS="${NS:-otel-demo}"
CM="${CM:-flagd-config}"

python3 - "$FLAG" "$WANT" "$NS" "$CM" <<'PY'
import json, subprocess, sys
flag, want, ns, cm = sys.argv[1:5]

raw = subprocess.run(["kubectl", "get", "cm", "-n", ns, cm, "-o", "json"],
                     capture_output=True, text=True, check=True).stdout
data = json.loads(raw)["data"]

# The chart has moved this key's name between releases, so find it rather than hardcode it.
key = next(k for k in data if "flag" in k.lower() or k.endswith(".json"))
doc = json.loads(data[key])

if flag not in doc["flags"]:
    sys.exit(f"no such flag: {flag}\navailable: {', '.join(sorted(doc['flags']))}")

variants = list(doc["flags"][flag]["variants"])
if want not in variants:
    sys.exit(f"'{want}' is not a variant of {flag}.\n"
             f"valid: {', '.join(map(str, variants))}\n"
             f"A name that does not exist is accepted silently and does nothing.")

doc["flags"][flag]["defaultVariant"] = want
patch = json.dumps({"data": {key: json.dumps(doc, indent=2)}})

# ⛔ patch, never apply. Helm created this ConfigMap, so `kubectl apply` prints a warning
# about a missing last-applied-configuration annotation. It works, and it looks like an error.
subprocess.run(["kubectl", "patch", "cm", cm, "-n", ns, "--type", "merge", "-p", patch],
               check=True)
print(f"{flag} -> {want}")
PY

kubectl rollout restart deploy/flagd -n "$NS"
kubectl rollout restart deploy/email -n "$NS"
echo
echo "Watch it with:  kubectl get pod -n $NS -l app.kubernetes.io/component=email -w"
