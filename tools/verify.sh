#!/bin/sh
# Verify one published release: check every SHA256 value, run --help, and run
# the demo server with one HTTP request.
#
# Usage: tools/verify.sh [vX.Y.Z]
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=${1:-}
if [ -z "$VERSION" ]; then
  VERSION=$(ls -d "$ROOT"/dist/v* 2>/dev/null | sort | tail -1 | sed 's|.*/||')
fi
[ -n "$VERSION" ] || { echo "no release under dist/" >&2; exit 1; }
DIST="$ROOT/dist/$VERSION"
[ -d "$DIST" ] || { echo "no such release: $VERSION" >&2; exit 1; }

echo "== checksums ($VERSION) =="
( cd "$DIST"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c SHA256SUMS
  else
    shasum -a 256 -c SHA256SUMS
  fi )

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) PLATFORM=darwin-arm64 ;;
  Linux-x86_64) PLATFORM=linux-x86_64 ;;
  *) echo "unsupported platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac
BIN="$DIST/$PLATFORM/umm-infer"
[ -x "$BIN" ] || { echo "no binary for $PLATFORM" >&2; exit 1; }

echo "== --help =="
"$BIN" serve --help >/dev/null
echo "ok"

PORT=${PORT:-43991}
LOG=$(mktemp "${TMPDIR:-/tmp}/umm-verify.XXXXXX")
echo "== demo server on 127.0.0.1:$PORT =="
"$BIN" serve --demo --model qwen3-native --host 127.0.0.1 --port "$PORT" >"$LOG" 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; rm -f "$LOG"' EXIT

i=0
until curl -sf "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 50 ]; then
    echo "server did not answer /health" >&2
    cat "$LOG" >&2
    exit 1
  fi
  sleep 0.2
done

BODY=$(curl -sS "http://127.0.0.1:$PORT/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3-native","messages":[{"role":"user","content":"hello"}]}')
case "$BODY" in
  *'"content":"echo: hello"'*) echo "ok: $BODY" ;;
  *) echo "unexpected response: $BODY" >&2; exit 1 ;;
esac

echo "verify: PASS"
