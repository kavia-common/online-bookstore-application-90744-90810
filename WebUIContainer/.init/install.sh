#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${WORKSPACE:-"/home/kavia/workspace/code-generation/online-bookstore-application-90744-90810/WebUIContainer"}
cd "$WORKSPACE"
# Decide if install required: missing node_modules or package-lock newer than node_modules
INSTALL_REQUIRED=0
if [ ! -d node_modules ]; then INSTALL_REQUIRED=1; fi
if [ -f package-lock.json ] && [ -d node_modules ]; then
  if [ "$(stat -c %Y package-lock.json)" -gt "$(stat -c %Y node_modules)" ]; then INSTALL_REQUIRED=1; fi
fi
# Check registry reachability using HTTPS (respects proxy env vars)
REG_OK=1
if command -v curl >/dev/null 2>&1; then
  if ! curl -sS --max-time 5 "https://registry.npmjs.org/-/v1/search?text=react" >/dev/null 2>&1; then REG_OK=0; fi
else
  REG_OK=0
fi
if [ $INSTALL_REQUIRED -eq 1 ]; then
  if [ $REG_OK -ne 1 ]; then echo "ERROR: network unavailable for npm install and node_modules missing or stale" >&2; exit 4; fi
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund || (echo "npm ci failed, falling back to npm i" && npm i --no-audit --no-fund)
  else
    npm i --no-audit --no-fund
  fi
fi
# Ensure react-scripts available locally; if not present but global exists, still prefer local for deterministic builds by installing devDependency
if [ ! -x node_modules/.bin/react-scripts ] && ! command -v react-scripts >/dev/null 2>&1; then
  if [ $REG_OK -ne 1 ]; then echo "ERROR: react-scripts missing and offline" >&2; exit 5; fi
  npm i --no-audit --no-fund --save-dev react-scripts@^5.0.1
fi
# Ensure serve available locally or globally; install local devDependency only if network available and missing
if [ ! -x node_modules/.bin/serve ] && ! command -v serve >/dev/null 2>&1 ]; then
  if [ $REG_OK -eq 1 ]; then npm i --no-audit --no-fund --save-dev serve@^14.0.0; else echo "WARN: serve not available locally and network offline; relying on global serve if present"; fi
fi
# Verify jest availability (prefer local)
if [ -x node_modules/.bin/jest ]; then echo "jest=local"; elif command -v jest >/dev/null 2>&1; then echo "jest=global"; else echo "ERROR: jest not available" >&2 && exit 6; fi
