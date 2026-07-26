# Dawbrain

Public mirror of release artifacts of Dawbrain Agent. For more information, see https://www.dawbrain.com

This repo exists so the install script can fetch binaries from anonymous GitHub URLs.

## Install

macOS / Linux:

    curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/install.sh | bash

Windows (PowerShell):

    iwr https://raw.githubusercontent.com/dawbrain/dist/main/install.ps1 | iex

## What gets installed

- Bridge (Ableton Remote Script), into your Ableton User Library
- Agent, into your user application data folder

Safe to re-run to upgrade.

## Uninstall

Quit Ableton Live first.

macOS:

    curl -fsSL https://raw.githubusercontent.com/dawbrain/dist/main/uninstall.sh | bash

Windows (PowerShell):

    iwr https://raw.githubusercontent.com/dawbrain/dist/main/uninstall.ps1 | iex

## Releases

Release tags are prefixed by component:

- `bridge-v<semver>` — Ableton Remote Script (`dawbrain-bridge.pyc` + `LICENSE`)
- `agent-v<semver>` — Local agent binary (`dawbrain-agent[.exe]` + `LICENSE`)
