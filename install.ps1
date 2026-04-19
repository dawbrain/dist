# DawBrain installer for Windows.
# Usage: iwr https://raw.githubusercontent.com/dawbrain/dist/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$DistRepo        = 'dawbrain/dist'
$GhApi           = "https://api.github.com/repos/$DistRepo/releases"
$AbletonUserLib  = Join-Path $env:USERPROFILE 'Documents\Ableton\User Library'
$BridgeDir       = Join-Path $AbletonUserLib 'Remote Scripts\DawBrain'
$AgentDir        = Join-Path $env:LOCALAPPDATA 'DawBrain'
$LogDir          = Join-Path $env:LOCALAPPDATA 'DawBrain\logs'

function Main {
    Check-AbletonUserLib
    $bridgeTag = Get-LatestTag 'bridge-'
    $agentTag  = Get-LatestTag 'agent-'
    Write-Host "Installing bridge $bridgeTag + agent $agentTag..."
    Install-Bridge $bridgeTag
    Install-Agent  $agentTag
    Write-Config
    Prune-AgentVersions
    Print-Done
}

function Check-AbletonUserLib {
    if (-not (Test-Path $AbletonUserLib)) {
        Write-Error "Ableton User Library not found at: $AbletonUserLib`nPlease open Ableton Live at least once so it creates this folder, then rerun."
    }
}

function Get-LatestTag([string]$prefix) {
    $releases = Invoke-RestMethod -Uri $GhApi
    $match = $releases | Where-Object { $_.tag_name.StartsWith($prefix) } | Select-Object -First 1
    if (-not $match) { Write-Error "No release found with prefix $prefix" }
    return $match.tag_name
}

function Install-Bridge([string]$tag) {
    New-Item -ItemType Directory -Force -Path $BridgeDir | Out-Null
    Write-Host "  downloading bridge..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$DistRepo/releases/download/$tag/dawbrain-bridge.pyc" -OutFile (Join-Path $BridgeDir '__init__.pyc')
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$DistRepo/releases/download/$tag/LICENSE" -OutFile (Join-Path $BridgeDir 'LICENSE')
}

function Install-Agent([string]$tag) {
    $version = $tag -replace '^agent-',''
    New-Item -ItemType Directory -Force -Path $AgentDir, $LogDir | Out-Null
    $tmp = Join-Path $env:TEMP "dawbrain-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Write-Host "  downloading agent..."
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/$DistRepo/releases/download/$tag/dawbrain-agent-windows.zip" -OutFile (Join-Path $tmp 'agent.zip')
    Expand-Archive -Path (Join-Path $tmp 'agent.zip') -DestinationPath $tmp -Force
    Copy-Item (Join-Path $tmp 'dawbrain-agent.exe') (Join-Path $AgentDir "agent-$version.exe") -Force
    Copy-Item (Join-Path $tmp 'LICENSE') (Join-Path $AgentDir 'LICENSE') -Force
    Remove-Item -Recurse -Force $tmp
    (Join-Path $AgentDir "agent-$version.exe") | Set-Content -Path (Join-Path $AgentDir '.last_installed') -NoNewline
}

function Write-Config {
    $agentPath = Get-Content (Join-Path $AgentDir '.last_installed') -Raw
    $cfg = @"
[process]
command = $agentPath
args =
cwd =
"@
    [System.IO.File]::WriteAllText((Join-Path $BridgeDir 'config.ini'), $cfg, (New-Object System.Text.UTF8Encoding($false)))
}

function Prune-AgentVersions {
    $keep = 2
    Get-ChildItem -Path $AgentDir -Filter 'agent-*' -File |
      Sort-Object LastWriteTime -Descending |
      Select-Object -Skip $keep |
      ForEach-Object {
          Write-Host "  pruning $($_.Name)"
          try { Remove-Item $_.FullName -Force -ErrorAction Stop }
          catch { Write-Warning "could not delete $($_.Name) (likely in use) — will retry next install" }
      }
}

function Print-Done {
    Write-Host ""
    Write-Host "DawBrain installed successfully."
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Open Ableton Live"
    Write-Host "  2. Preferences -> Link, Tempo & MIDI -> Control Surface -> DawBrain"
    Write-Host "  3. A browser window will open for device auth on first agent run"
    Write-Host ""
    Write-Host "Config:    $BridgeDir\config.ini"
    Write-Host "Logs:      $LogDir\agent-stdio.log (raw)"
    Write-Host ""
}

Main
