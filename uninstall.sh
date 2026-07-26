#!/usr/bin/env bash
# Dawbrain uninstaller for macOS.
# Usage: curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/uninstall.sh | bash
set -euo pipefail

main() {
  [[ "$(uname -s)" == "Darwin" ]] || { echo "ERROR: uninstall.sh is for macOS. Use uninstall.ps1 on Windows." >&2; exit 1; }
  if pgrep -f 'Ableton Live' >/dev/null 2>&1; then
    echo "ERROR: Ableton Live is running. Quit it, then rerun." >&2
    exit 1
  fi
  echo "Removing Dawbrain..."
  rm -rf \
    "${HOME}/Music/Ableton/User Library/Remote Scripts/Dawbrain" \
    "${HOME}/Library/Application Support/Dawbrain" \
    "${HOME}/Library/Logs/Dawbrain" \
    "${HOME}/.dawbrain"
  cat <<'EOF'

Dawbrain uninstalled.

If Dawbrain is still selected under Ableton Live → Preferences →
Link, Tempo & MIDI → Control Surface, set it to None.

EOF
}

main "$@"
