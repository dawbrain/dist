#!/usr/bin/env bash
# Dawbrain installer for macOS.
# Usage: curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/install.sh | bash
set -euo pipefail

DIST_REPO="dawbrain/dist"
GH_API="https://api.github.com/repos/${DIST_REPO}/releases"
ABLETON_USER_LIB="${HOME}/Music/Ableton/User Library"
BRIDGE_DIR="${ABLETON_USER_LIB}/Remote Scripts/Dawbrain"
AGENT_DIR="${HOME}/Library/Application Support/Dawbrain"
LOG_DIR="${HOME}/Library/Logs/Dawbrain"

main() {
  print_title
  [[ "$(uname -s)" == "Darwin" ]] || { echo "ERROR: install.sh is for macOS. Use install.ps1 on Windows." >&2; exit 1; }
  check_ableton_user_lib
  local bridge_tag agent_tag bridge_current agent_current
  bridge_tag=$(latest_tag "bridge-")
  agent_tag=$(latest_tag "agent-")
  bridge_current=$(installed_tag "${BRIDGE_DIR}/.version")
  agent_current=$(installed_tag "${AGENT_DIR}/.version")

  if [[ "$bridge_current" == "$bridge_tag" && "$agent_current" == "$agent_tag" ]]; then
    echo "Already up to date (bridge ${bridge_tag}, agent ${agent_tag})."
    exit 0
  fi

  echo "Installing bridge ${bridge_tag} + agent ${agent_tag}..."
  if [[ "$bridge_current" == "$bridge_tag" ]]; then
    echo "  bridge already at ${bridge_tag}, skipping"
  else
    install_bridge "$bridge_tag"
  fi
  if [[ "$agent_current" == "$agent_tag" ]]; then
    echo "  agent already at ${agent_tag}, skipping"
  else
    install_agent "$agent_tag"
  fi
  write_config
  prune_agent_versions
  print_done
}

installed_tag() {
  # $1 = path to .version file. Prints the recorded tag or empty.
  local marker="$1"
  [[ -f "$marker" ]] || { echo ""; return; }
  tr -d '[:space:]' < "$marker"
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
  #
  # Walks every page of the releases API, not just the first. The default page
  # holds 30 releases, and each component's tags can occupy all of them, which
  # left the other component's newest release outside the response entirely and
  # failed the lookup even though the release existed.
  #
  local prefix="$1" page=1 tags="" body page_tags count latest

  while [ "$page" -le 20 ]; do
    if ! body=$(curl -fsSL -H 'Accept: application/vnd.github+json' \
        "${GH_API}?per_page=100&page=${page}"); then
      echo "ERROR: could not reach the releases API" >&2
      return 1
    fi
    page_tags=$(printf '%s' "$body" \
      | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
      | sed 's/.*"\([^"]*\)"$/\1/' || true)
    if [ -z "$page_tags" ]; then
      break
    fi
    tags="${tags}${page_tags}
"
    count=$(printf '%s\n' "$page_tags" | grep -c . || true)
    if [ "$count" -lt 100 ]; then
      break
    fi
    page=$((page + 1))
  done

  # Highest version wins, not most recently published: a numeric sort over
  # MAJOR.MINOR.PATCH doesn't care what order the API returned releases in,
  # and a plain lexical sort would pick v0.1.9 over v0.1.10.
  latest=$(printf '%s' "$tags" \
    | grep "^${prefix}v" \
    | sed "s/^${prefix}v//" \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -n 1 || true)

  if [ -z "$latest" ]; then
    echo "ERROR: no release found with prefix ${prefix}" >&2
    return 1
  fi
  printf '%sv%s\n' "$prefix" "$latest"
}

install_bridge() {
  local tag="$1"
  mkdir -p "$BRIDGE_DIR"
  echo "  downloading bridge..."
  curl -fsSL -o "${BRIDGE_DIR}/__init__.pyc" \
    "https://github.com/${DIST_REPO}/releases/download/${tag}/dawbrain-bridge.pyc"
  curl -fsSL -o "${BRIDGE_DIR}/LICENSE" \
    "https://github.com/${DIST_REPO}/releases/download/${tag}/LICENSE"
  printf '%s' "$tag" > "${BRIDGE_DIR}/.version"
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
  printf '%s' "$tag" > "${AGENT_DIR}/.version"
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
  # Keep the 2 highest-versioned agent-* files; delete the rest. Ordering by
  # version rather than mtime matches how latest_tag picks a release, so a
  # reinstall that touches an old file can't make it look current.
  #
  # Deliberately not `find ... | xargs ls -t`: with no matches, xargs can still
  # run `ls -t` with no arguments, which lists the CURRENT DIRECTORY, and those
  # names then reach rm. For a `curl | bash` install that is wherever the user
  # happened to be standing. Globbing in the target directory can't wander.
  # Only bare version strings cross the pipe, never paths: AGENT_DIR contains a
  # space ("Application Support"), so piping filenames would word-split.
  local keep=2 files=() version old
  shopt -s nullglob
  files=( "${AGENT_DIR}"/agent-* )
  shopt -u nullglob
  if [ "${#files[@]}" -le "$keep" ]; then
    return 0
  fi
  printf '%s\n' "${files[@]}" \
    | sed 's|.*/agent-||' \
    | sort -t. -k1,1nr -k2,2nr -k3,3nr \
    | tail -n +$((keep + 1)) \
    | while IFS= read -r version; do
        old="${AGENT_DIR}/agent-${version}"
        if [ -f "$old" ]; then
          echo "  pruning $(basename "$old")"
          rm -f -- "$old"
        fi
      done
}

print_title() {
  cat <<'EOF'
 ____                 _               _
|  _ \  __ ___      _| |__  _ __ __ _(_)_ __
| | | |/ _` \ \ /\ / / '_ \| '__/ _` | | '_ \
| |_| | (_| |\ V  V /| |_) | | | (_| | | | | |
|____/ \__,_| \_/\_/ |_.__/|_|  \__,_|_|_| |_|

EOF
}

print_done() {
  cat <<EOF

Dawbrain installed successfully.

Next steps:
  1. Open Ableton Live
  2. Preferences → Link, Tempo & MIDI → Control Surface → Dawbrain
  3. A browser window will open for device auth on first agent run

Config:    ${BRIDGE_DIR}/config.ini
Logs:      ${LOG_DIR}/agent.log

EOF
}

main "$@"
