# Dawbrain uninstaller for Windows.
# Usage: iwr https://raw.githubusercontent.com/dawbrain/dist/main/uninstall.ps1 | iex

$ErrorActionPreference = 'Stop'

function Main {
    if (Get-Process -Name 'Ableton Live*' -ErrorAction SilentlyContinue) {
        Write-Error "Ableton Live is running. Quit it, then rerun."
    }
    Write-Host "Removing Dawbrain..."
    $targets = @(
        (Join-Path $env:USERPROFILE 'Documents\Ableton\User Library\Remote Scripts\Dawbrain'),
        (Join-Path $env:LOCALAPPDATA 'Dawbrain'),
        (Join-Path $env:USERPROFILE '.dawbrain')
    )
    foreach ($target in $targets) {
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
        }
    }
    Write-Host ""
    Write-Host "Dawbrain uninstalled."
    Write-Host ""
    Write-Host "If Dawbrain is still selected under Ableton Live -> Preferences ->"
    Write-Host "Link, Tempo & MIDI -> Control Surface, set it to None."
    Write-Host ""
}

Main
