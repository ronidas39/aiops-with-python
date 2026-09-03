#!/usr/bin/env bash
# Print every fault this demo ships, and what each one can be set to.
#
#   ./bin/faults.sh          # or: make faults
#
# ⛔ TWO BUGS LIVED IN THIS FILE, AND THE SECOND ONE I INTRODUCED WHILE FIXING THE FIRST.
#
# 1. The Python was inside `python3 -c '...'`, and the Python itself contains single quotes,
#    in `', '.join(...)` and `f['variants']`. The shell ended its own string at the first of
#    them, so python3 got a truncated program:
#        SyntaxError: f-string: expecting a valid expression after '{'
#
# 2. The obvious fix, `kubectl ... | python3 - <<'PY'`, is also broken, and quietly. A heredoc
#    IS stdin, so the piped JSON never reaches the program and json.load reads an empty
#    string. It fails with "Expecting value: line 1 column 1".
#
# So the Python calls kubectl itself and nothing is piped. That is the same shape as
# fault.sh, which has always worked for exactly this reason.
#
# ⛔ `bash -n` PASSES ON BOTH OF THOSE. The shell syntax was never wrong. Only running it
# catches either, which is why bin/selftest.sh exists.
set -euo pipefail

command -v python3 >/dev/null || { echo "python3 is not installed. On a Mac: xcode-select --install"; exit 2; }

python3 - "${NS:-otel-demo}" "${CM:-flagd-config}" <<'PY'
import json, subprocess, sys

ns, cm = sys.argv[1], sys.argv[2]
raw = subprocess.run(["kubectl", "get", "cm", "-n", ns, cm, "-o", "json"],
                     capture_output=True, text=True, check=True).stdout
data = json.loads(raw)["data"]

# The chart has moved this key's name between releases, so find it rather than hardcode it.
key = next(k for k in data if "flag" in k.lower() or k.endswith(".json"))

for name, flag in sorted(json.loads(data[key])["flags"].items()):
    now = flag.get("defaultVariant")
    variants = ", ".join(str(v) for v in flag["variants"])
    print(f"{name:32} now={now:8} variants={variants}")
PY
