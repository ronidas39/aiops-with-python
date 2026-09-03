#!/usr/bin/env bash
# Run every script in bin/ for real, against a fake kubectl, with no cluster.
#
#   ./bin/selftest.sh
#
# ⛔ WHY THIS EXISTS. `make faults` shipped broken. The Python inside it was passed with
# `python3 -c '...'` and the Python contained single quotes, so the shell truncated the
# program and it died with a SyntaxError the moment anyone ran it. It was checked with
# `bash -n`, which passes, because the SHELL syntax was never wrong.
#
# Then the obvious fix, piping kubectl into `python3 - <<'PY'`, was broken too and in a
# quieter way: a heredoc is stdin, so the piped JSON never arrives and json.load sees an
# empty string.
#
# Two bugs, neither visible by reading, both caught in one second by running. So this runs
# them. It needs no cluster and no AWS: kubectl is replaced with a stub that returns a small
# fixed flag file, which is enough to exercise every line that parses or prints.
set -uo pipefail
cd "$(dirname "$0")/.."

STUB=$(mktemp -d)
cat > "$STUB/kubectl" <<'FAKE'
#!/usr/bin/env bash
case "$1" in
  get) cat <<'JSON'
{"data":{"demo.flagd.json":"{\"flags\":{\"emailMemoryLeak\":{\"defaultVariant\":\"off\",\"variants\":{\"off\":0,\"1x\":1,\"100x\":100,\"10000x\":10000}},\"adFailure\":{\"defaultVariant\":\"off\",\"variants\":{\"off\":0,\"on\":1}}}}"}}
JSON
  ;;
  *) echo "kubectl $*" ;;
esac
FAKE
cat > "$STUB/aws" <<'FAKE'
#!/usr/bin/env bash
echo 0
FAKE
chmod +x "$STUB/kubectl" "$STUB/aws"
export PATH="$STUB:$PATH"

fail=0
run() {
  local name="$1"; shift
  printf "  %-46s" "$name"
  if out=$("$@" 2>&1); then echo "PASS"
  else echo "FAIL"; echo "$out" | sed 's/^/      /'; fail=1; fi
}
refuses() {
  local name="$1"; shift
  printf "  %-46s" "$name"
  if out=$("$@" 2>&1); then echo "FAIL (should have refused)"; fail=1
  else echo "PASS"; fi
}

echo
echo "  bin/ self test, no cluster needed"
echo
run "faults.sh lists the flags"                ./bin/faults.sh
run "fault.sh sets a real variant"             ./bin/fault.sh emailMemoryLeak 100x
refuses "fault.sh refuses a variant that does not exist" ./bin/fault.sh emailMemoryLeak on
refuses "fault.sh refuses a flag that does not exist"    ./bin/fault.sh nosuchflag 100x
refuses "fault.sh refuses with no arguments"             ./bin/fault.sh
run "leftovers.sh counts"                      ./bin/leftovers.sh

# Every make target must at least be resolvable.
for t in $(grep '^\.PHONY' Makefile | cut -d: -f2); do
  printf "  %-46s" "make $t resolves"
  if make -n "$t" >/dev/null 2>&1; then echo "PASS"; else echo "FAIL"; fail=1; fi
done

rm -rf "$STUB"
echo
[ $fail -eq 0 ] && echo "  every script runs." || echo "  ⛔ SOMETHING IS BROKEN. Do not record."
exit $fail
