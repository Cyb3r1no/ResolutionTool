#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Applies NV_Modes registry entries to persist custom NVIDIA resolutions.
.DESCRIPTION
    Reads the game resolution from config/settings.json, checks existing
    NV_Modes registry values, and appends the custom resolution entry
    only if it does not already exist.
#>

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigPath = Join-Path (Split-Path -Parent $ScriptRoot) "config\settings.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config not found: $ConfigPath"
    exit 1
}

$cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$gameRes = "$($cfg.game.width)x$($cfg.game.height)"
$newEntry = "${gameRes}x8,16,32,64=1F;"

$found = $false

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class" -Recurse -ErrorAction SilentlyContinue |
ForEach-Object {
    try {
        $prop = Get-ItemProperty $_.PSPath -Name "NV_Modes" -ErrorAction Stop
        $current = $prop.NV_Modes
        # Handle string array (registry REG_MULTI_SZ)
        if ($current -is [array]) { $current = $current -join "" }

        $found = $true

        # Check if this resolution already exists in the mode string
        if ($current -match [regex]::Escape("${gameRes}x")) {
            Write-Host "Already present in: $($_.PSPath)"
            return
        }

        # Append before the trailing entries, or at the end of the string
        $updated = $current.TrimEnd() + " $newEntry"
        Set-ItemProperty -Path $_.PSPath -Name "NV_Modes" -Value @($updated)
        Write-Host "Appended ${gameRes} to: $($_.PSPath)"
    } catch {}
}

if (-not $found) {
    Write-Warning "No NV_Modes registry keys found. Is an NVIDIA driver installed?"
    exit 1
}

Write-Host "NV_Modes check complete for: $gameRes"
