#!/usr/bin/env bash
# Tests nfactory-forge-devkit-mcp.sh config — the .mcp.json merge. Offline: pac is stubbed.
set -uo pipefail
cd "$(dirname "$0")"
S="$PWD/../scripts/nfactory-forge-devkit-mcp.sh"
fail() { echo "FAIL: $*"; exit 1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir "$T/bin"
cat > "$T/bin/pac" <<'EOF'
#!/bin/sh
echo "Index Active Kind      Name   User"
echo "[1]          UNIVERSAL dev    a@b"
echo "[2]   *      UNIVERSAL prod   a@b"
EOF
chmod +x "$T/bin/pac"
cd "$T"

echo '{"mcpServers":{"other":{"command":"x"}}}' > .mcp.json
PATH="$T/bin:$PATH" bash "$S" config >/dev/null || fail "config exited non-zero"
jq -e '.mcpServers.other.command == "x"' .mcp.json >/dev/null || fail "other server lost"
jq -e '.mcpServers["dynamicscrm-devkit"].env.DEVKIT_PAC_PROFILE == "prod"' .mcp.json >/dev/null \
  || fail "active pac profile not used: $(cat .mcp.json)"
jq -e '.mcpServers["dynamicscrm-devkit"].args | index("readonly")' .mcp.json >/dev/null || fail "not readonly"

# A user-edited entry is kept.
jq '.mcpServers["dynamicscrm-devkit"].args = ["mcp","--category","all"]' .mcp.json > m && mv m .mcp.json
bash "$S" config --profile dev >/dev/null || fail "rerun exited non-zero"
jq -e '.mcpServers["dynamicscrm-devkit"].args | index("all")' .mcp.json >/dev/null || fail "user edit overwritten"

# Unreadable JSON is never overwritten.
echo '{bad' > .mcp.json
bash "$S" config --profile dev >/dev/null 2>&1 && fail "bad JSON should fail"
[ "$(cat .mcp.json)" = '{bad' ] || fail "bad JSON was overwritten"

# Fresh file, explicit profile.
rm .mcp.json
bash "$S" config --profile dev >/dev/null || fail "fresh config failed"
jq -e '.mcpServers["dynamicscrm-devkit"].env.DEVKIT_PAC_PROFILE == "dev"' .mcp.json >/dev/null || fail "--profile ignored"

echo "PASS: devkit-mcp config"
