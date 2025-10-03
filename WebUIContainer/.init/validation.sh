#!/usr/bin/env bash
set -euo pipefail
# Minimal validation wrapper: build, serve, smoke-check, shutdown
WORKSPACE=${WORKSPACE:-"/home/kavia/workspace/code-generation/online-bookstore-application-90744-90810/WebUIContainer"}
cd "$WORKSPACE"
# Ensure env is sourced for this run so PATH contains npm global bin if needed
if [ -r /etc/profile.d/webui_node.sh ]; then . /etc/profile.d/webui_node.sh || true; fi
# Build using local react-scripts (deps-001 ensures local install) - fail fast with logs
npm run build --silent
PORT=${VALIDATION_PORT:-5000}
LOGFILE="$WORKSPACE/validation_serve.log"
EVIDENCE="$WORKSPACE/validation_evidence.txt"
TMP_INDEX="/tmp/webui_index.html"
RETRIES=${VALIDATION_RETRIES:-30}
CURL_TIMEOUT=5
# Determine serve command
if [ -x node_modules/.bin/serve ]; then
  SERVE_BIN="node_modules/.bin/serve"
elif command -v serve >/dev/null 2>&1; then
  SERVE_BIN="$(command -v serve)"
else
  echo "ERROR: serve not available locally or globally" >&2 && exit 6
fi
# Start server with setsid to avoid shell job control detaching; capture PID
setsid "$SERVE_BIN" -s build -l 127.0.0.1:$PORT >"$LOGFILE" 2>&1 &
SERVER_PID=$!
trap 'if kill -0 "$SERVER_PID" 2>/dev/null; then kill "$SERVER_PID" 2>/dev/null || true; fi; rm -f "$TMP_INDEX"' EXIT
# Wait for server to respond
i=0
HTTP_OK=0
HTTP_CODE="000"
while [ $i -lt $RETRIES ]; do
  HTTP_CODE=$(curl -fsS -o "$TMP_INDEX" -w '%{http_code}' --max-time $CURL_TIMEOUT http://127.0.0.1:$PORT/ 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ] && [ -s "$TMP_INDEX" ]; then HTTP_OK=1; break; fi
  i=$((i+1))
  sleep 1
done
if [ $HTTP_OK -ne 1 ]; then
  echo "Validation failed: server did not respond with 200 within $RETRIES seconds" >"$EVIDENCE"
  echo "curl_http_code=$HTTP_CODE" >>"$EVIDENCE" || true
  tail -n 200 "$LOGFILE" >>"$EVIDENCE" || true
  exit 4
fi
# Record evidence
echo "http_code=$HTTP_CODE" > "$EVIDENCE"
head -n 40 "$TMP_INDEX" >> "$EVIDENCE" || true
tail -n 200 "$LOGFILE" >> "$EVIDENCE" || true
# Clean up: trap will kill server
rm -f "$TMP_INDEX" || true
echo "validation: OK - evidence saved to $EVIDENCE"
