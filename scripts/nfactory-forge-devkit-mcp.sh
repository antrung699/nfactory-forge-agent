#!/usr/bin/env bash
# nfactory-forge-devkit-mcp.sh — install the Dynamics CRM DevKit `devkit` tool and
# wire its MCP server into the project's .mcp.json.
#
# The pinned build (4.44.44.44) is not on NuGet; it lives only in the DevKit repo's
# v5/Published folder. The author re-uploads new builds under this same version, so
# the URL is pinned to commit e0487de (2026-10-13) and the SHA-256 is that file's own
# (the build manifest beside it is stale). To move to a newer build, update both.
#
# Usage:
#   nfactory-forge-devkit-mcp.sh install                 # .NET 10 check + devkit tool
#   nfactory-forge-devkit-mcp.sh config [--profile <pac profile>] [--file .mcp.json]
#
# config adds mcpServers.dynamicscrm-devkit (readonly, FromPac) and keeps every other
# server. An existing dynamicscrm-devkit entry is left as the user edited it.
# --profile defaults to the active `pac auth list` profile.
#
# Exit: 0 done · 1 failed (download, checksum, dotnet) · 64 usage
#       69 a system tool is missing — stdout's last line is the command to run
set -euo pipefail

VERSION="4.44.44.44"
SHA256="306382d6ca8e59d26911c1ff25879dfabfd4eba3a1ac75893a96efe8c45851bd"
PKG="DynamicsCrm.DevKit.Cli.$VERSION.nupkg"
URL="${NFACTORY_FORGE_DEVKIT_URL:-https://raw.githubusercontent.com/phuocle/Dynamics-Crm-DevKit/e0487de530eefac0600d8e3fc0b4d241cc869132/v5/Published/$VERSION/$PKG}"
SERVER="dynamicscrm-devkit"

need() {  # need <tool> <why> <mac cmd> <other cmd>
  echo "Needs your machine: $1 isn't installed. $2"
  if [ "$(uname -s)" = "Darwin" ]; then echo "$3"; else echo "$4"; fi
  exit 69
}

installed_version() {
  dotnet tool list --global 2>/dev/null | awk 'tolower($1)=="dynamicscrm.devkit.cli"{print $2}'
}

cmd_install() {
  command -v dotnet >/dev/null && dotnet --list-sdks 2>/dev/null | grep -q '^10\.' \
    || need ".NET 10 SDK" "DevKit's devkit tool runs on it." \
            "brew install --cask dotnet-sdk" \
            "curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0"

  local have; have="$(installed_version)"
  if [ "$have" = "$VERSION" ]; then
    echo "✓ devkit $VERSION already installed"
  else
    local tmp; tmp="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" EXIT
    curl -fsSL "$URL" -o "$tmp/$PKG" || { echo "✗ download failed: $URL" >&2; exit 1; }
    local got; got="$(shasum -a 256 "$tmp/$PKG" 2>/dev/null || sha256sum "$tmp/$PKG")"
    got="$(echo "${got%% *}" | tr 'A-F' 'a-f')"
    [ "$got" = "$SHA256" ] || { echo "✗ checksum mismatch for $PKG (got $got)" >&2; exit 1; }
    if [ -n "$have" ]; then
      dotnet tool update --global DynamicsCrm.DevKit.Cli --version "$VERSION" --add-source "$tmp" --allow-downgrade >/dev/null
    else
      dotnet tool install --global DynamicsCrm.DevKit.Cli --version "$VERSION" --add-source "$tmp" >/dev/null
    fi
    echo "✓ devkit $VERSION installed${have:+ (was $have)}"
  fi
  command -v devkit >/dev/null || echo "⚠️  devkit is not on PATH yet: add ~/.dotnet/tools to PATH, then restart Claude Code"
}

cmd_config() {
  local profile="" file=".mcp.json"
  while [ $# -gt 0 ]; do
    case "$1" in
      --profile) profile="${2:-}"; shift 2 ;;
      --file) file="${2:-}"; shift 2 ;;
      *) echo "unknown option: $1" >&2; exit 64 ;;
    esac
  done
  if [ -z "$profile" ]; then
    command -v pac >/dev/null || need "Power Platform CLI (pac)" "DevKit signs in through a pac profile." \
      "dotnet tool install --global Microsoft.PowerApps.CLI.Tool && pac auth create" \
      "dotnet tool install --global Microsoft.PowerApps.CLI.Tool && pac auth create"
    profile="$(pac auth list 2>/dev/null | awk '$2=="*"{print $4; exit}')"
    [ -n "$profile" ] || { echo "✗ no active pac profile: run pac auth create, or pass --profile" >&2; exit 1; }
  fi
  python3 - "$file" "$SERVER" "$profile" <<'PY'
import json, os, sys
path, name, profile = sys.argv[1:]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)  # bad JSON stops here: never overwrite a file we can't read
servers = data.setdefault("mcpServers", {})
if name in servers:
    print(f"✓ {name} already in {path} (left as is)")
    sys.exit(0)
servers[name] = {
    "command": "devkit",
    "args": ["mcp", "DynamicsCrm.DevKit", "--category", "readonly"],
    "env": {"DEVKIT_AUTH_TYPE": "FromPac", "DEVKIT_PAC_PROFILE": profile},
}
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print(f"✓ {name} added to {path} (readonly, pac profile {profile})")
PY
}

case "${1:-}" in
  install) shift; cmd_install "$@" ;;
  config) shift; cmd_config "$@" ;;
  -h|--help) sed -n '2,19p' "$0" ;;
  *) sed -n '10,12p' "$0" >&2; exit 64 ;;
esac
