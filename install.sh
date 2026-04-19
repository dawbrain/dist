#!/usr/bin/env bash
# DawBrain installer for macOS.
# Usage: curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/install.sh | bash
set -euo pipefail

DIST_REPO="dawbrain/dist"
GH_API="https://api.github.com/repos/${DIST_REPO}/releases"
ABLETON_USER_LIB="${HOME}/Music/Ableton/User Library"
BRIDGE_DIR="${ABLETON_USER_LIB}/Remote Scripts/DawBrain"
AGENT_DIR="${HOME}/Library/Application Support/DawBrain"
LOG_DIR="${HOME}/Library/Logs/DawBrain"

main() {
  [[ "$(uname -s)" == "Darwin" ]] || { echo "ERROR: install.sh is for macOS. Use install.ps1 on Windows." >&2; exit 1; }
  check_ableton_user_lib
  local bridge_tag agent_tag
  bridge_tag=$(latest_tag "bridge-")
  agent_tag=$(latest_tag "agent-")
  echo "Installing bridge ${bridge_tag} + agent ${agent_tag}..."
  install_bridge "$bridge_tag"
  install_agent "$agent_tag"
  write_config
  prune_agent_versions
  print_done
}

check_ableton_user_lib() {
  if [[ ! -d "$ABLETON_USER_LIB" ]]; then
    echo "ERROR: Ableton User Library not found at:" >&2
    echo "  $ABLETON_USER_LIB" >&2
    echo "Please open Ableton Live at least once so it creates this folder, then rerun." >&2
    exit 1
  fi
}

latest_tag() {
  # $1 = prefix, e.g. "bridge-"
  local prefix="$1"
  curl -fsSL "$GH_API" | python3 -c "
import json, sys
releases = json.load(sys.stdin)
matches = [r for r in releases if r['tag_name'].startswith('$prefix')]
if not matches:
    sys.stderr.write('ERROR: no release found with prefix $prefix\n')
    sys.exit(1)
# releases are returned newest-first by the API
print(matches[0]['tag_name'])
"
}

install_bridge() {
  local tag="$1"
  mkdir -p "$BRIDGE_DIR"
  echo "  downloading bridge..."
  curl -fsSL -o "${BRIDGE_DIR}/__init__.pyc" \
    "https://github.com/${DIST_REPO}/releases/download/${tag}/dawbrain-bridge.pyc"
  curl -fsSL -o "${BRIDGE_DIR}/LICENSE" \
    "https://github.com/${DIST_REPO}/releases/download/${tag}/LICENSE"
}

install_agent() {
  local tag="$1"
  # The agent release on dawbrain/dist has per-OS zips. Grab the macOS one.
  local version="${tag#agent-}"    # strip "agent-" prefix
  mkdir -p "$AGENT_DIR" "$LOG_DIR"
  local tmp
  tmp=$(mktemp -d)
  echo "  downloading agent..."
  curl -fsSL -o "${tmp}/agent.zip" \
    "https://github.com/${DIST_REPO}/releases/download/${tag}/dawbrain-agent-macos.zip"
  unzip -q -o "${tmp}/agent.zip" -d "${tmp}/extract"
  # agent zip contents: dawbrain-agent + LICENSE
  install -m 0755 "${tmp}/extract/dawbrain-agent" "${AGENT_DIR}/agent-${version}"
  cp "${tmp}/extract/LICENSE" "${AGENT_DIR}/LICENSE"
  rm -rf "$tmp"
  echo "${AGENT_DIR}/agent-${version}" > "${AGENT_DIR}/.last_installed"
}

write_config() {
  local agent_path
  agent_path=$(cat "${AGENT_DIR}/.last_installed")
  cat > "${BRIDGE_DIR}/config.ini" <<EOF
[process]
command = ${agent_path}
args =
cwd =
EOF
}

prune_agent_versions() {
  # Keep the 2 most-recent agent-* files; delete older.
  # Sorting by mtime descending.
  local keep=2
  find "$AGENT_DIR" -maxdepth 1 -type f -name 'agent-*' -print0 \
    | xargs -0 ls -t \
    | tail -n +$((keep + 1)) \
    | while read -r old; do
        echo "  pruning $(basename "$old")"
        rm -f "$old"
      done
}

print_done() {
  cat <<EOF

DawBrain installed successfully.

Next steps:
  1. Open Ableton Live
  2. Preferences → Link, Tempo & MIDI → Control Surface → DawBrain
  3. A browser window will open for device auth on first agent run

Config:    ${BRIDGE_DIR}/config.ini
Logs:      ${LOG_DIR}/agent.log

EOF
}

main "$@"
