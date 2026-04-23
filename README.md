# dawbrain/dist

Public mirror of release artifacts.

This repo exists so the install script can fetch binaries from anonymous GitHub URLs.

## Install

macOS / Linux:

    curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/install.sh | bash

Windows (PowerShell):

    iwr https://raw.githubusercontent.com/dawbrain/dist/main/install.ps1 | iex

## What gets installed

- Bridge (Ableton Remote Script) → `<Ableton User Library>/Remote Scripts/Dawbrain/`
- Agent binary → `~/Library/Application Support/Dawbrain/` (macOS) / `%LOCALAPPDATA%\Dawbrain\` (Windows)
- Logs → `~/Library/Logs/Dawbrain/` (macOS) / `%LOCALAPPDATA%\Dawbrain\logs\` (Windows)

Idempotent — safe to re-run to upgrade.

## Releases

Release tags are prefixed by component:

- `bridge-v<semver>` — Ableton Remote Script (`dawbrain-bridge.pyc` + `LICENSE`)
- `agent-v<semver>` — Local agent binary (`dawbrain-agent[.exe]` + `LICENSE`)
