# dawbrain/dist

Public mirror of release artifacts from the private `dawbrain/bridge` and `dawbrain/agent` repos.

This repo exists so the install script can fetch binaries from anonymous GitHub URLs. Source code lives in the private repos; only compiled, obfuscated, LICENSE-noticed artifacts land here.

## Releases

Release tags are prefixed by component:

- `bridge-v<semver>` — Ableton Remote Script (`dawbrain-bridge.pyc` + `LICENSE`)
- `agent-v<semver>` — Local agent binary (`dawbrain-agent[.exe]` + `LICENSE`)

Install scripts live at the root of `main`:
- macOS / Linux: `install.sh`
- Windows: `install.ps1`

## How to install

See the root of this repo for one-liners.
