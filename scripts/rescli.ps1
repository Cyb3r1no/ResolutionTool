#Requires -Version 5.1
<#
.SYNOPSIS
    rescli - Resolution profile manager for gaming and desktop use.
.DESCRIPTION
    Manages display resolution switching, NVIDIA custom resolution registry
    entries, and multi-monitor gaming/normal mode toggling.
.EXAMPLE
    .\rescli.ps1 game
    .\rescli.ps1 native
    .\rescli.ps1 status
#>

param(
    [Parameter(Position = 0)]
    [ValidateSet("game", "native", "fix-nvidia", "gaming-mode", "normal-mode", "status", "config", "help")]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
$ProjectRoot = Split-Path -Parent $ScriptDir

$NirCmd     = Join-Path $ProjectRoot "bin\nircmd.exe"
$ConfigPath = Join-Path $ProjectRoot "config\settings.json"
$NVScript   = Join-Path $ScriptDir "NV_Modes.ps1"

# --- Helpers ---

function Load-Config {
    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Config not found: $ConfigPath"
        exit 1
    }
    return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}


function Get-CurrentResolution {
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    return @{ Width = $screen.Width; Height = $screen.Height }
}

function Set-Resolution {
    param([int]$Width, [int]$Height, [int]$BitDepth)
    if (-not (Test-Path $NirCmd)) {
        Write-Error "nircmd.exe not found: $NirCmd"
        exit 1
    }
    Write-Host "Changing resolution to ${Width}x${Height}"
    Start-Process -FilePath $NirCmd `
        -ArgumentList "setdisplay $Width $Height $BitDepth" `
        -Wait `
        -NoNewWindow
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Elevated {
    param([string]$ScriptArgs)
    $ps = (Get-Process -Id $PID).Path
    Start-Process $ps -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.ScriptName)`" $ScriptArgs" -WindowStyle Hidden
    exit
}

# --- Commands ---

function Invoke-Game {
    $cfg = Load-Config
    Set-Resolution -Width $cfg.game.width -Height $cfg.game.height -BitDepth $cfg.bitDepth
}

function Invoke-Native {
    $cfg = Load-Config
    Set-Resolution -Width $cfg.native.width -Height $cfg.native.height -BitDepth $cfg.bitDepth
}

function Invoke-FixNvidia {
    if (-not (Test-Admin)) {
        Restart-Elevated "fix-nvidia"
        return
    }
    & $NVScript
}

function Invoke-GamingMode {
    $cfg = Load-Config
    # Disable secondary displays if configured
    foreach ($display in $cfg.secondaryDisplays) {
        Start-Process -FilePath $NirCmd -ArgumentList "setdisplay monitor:$display 0 0 0" -Wait -NoNewWindow
    }
    Invoke-Game
}

function Invoke-NormalMode {
    $cfg = Load-Config
    # Re-enable secondary displays if configured
    foreach ($display in $cfg.secondaryDisplays) {
        Start-Process -FilePath $NirCmd -ArgumentList "setdisplay monitor:$display 0 0 0" -Wait -NoNewWindow
    }
    Invoke-Native
}

function Invoke-Status {
    $res = Get-CurrentResolution
    $cfg = Load-Config
    Write-Host "Current   : $($res.Width)x$($res.Height)"
    Write-Host "Native    : $($cfg.native.width)x$($cfg.native.height)"
    Write-Host "Game      : $($cfg.game.width)x$($cfg.game.height)"
}

function Invoke-Config {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $cfg = Load-Config

    # --- Form ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ResolutionTool Config"
    $form.Size = New-Object System.Drawing.Size(320, 200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    # --- Width label + input ---
    $lblWidth = New-Object System.Windows.Forms.Label
    $lblWidth.Text = "Game resolution width:"
    $lblWidth.Location = New-Object System.Drawing.Point(20, 20)
    $lblWidth.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblWidth)

    $txtWidth = New-Object System.Windows.Forms.TextBox
    $txtWidth.Text = "$($cfg.game.width)"
    $txtWidth.Location = New-Object System.Drawing.Point(180, 18)
    $txtWidth.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($txtWidth)

    # --- Height label + input ---
    $lblHeight = New-Object System.Windows.Forms.Label
    $lblHeight.Text = "Game resolution height:"
    $lblHeight.Location = New-Object System.Drawing.Point(20, 55)
    $lblHeight.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($lblHeight)

    $txtHeight = New-Object System.Windows.Forms.TextBox
    $txtHeight.Text = "$($cfg.game.height)"
    $txtHeight.Location = New-Object System.Drawing.Point(180, 53)
    $txtHeight.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($txtHeight)

    # --- Save button ---
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "Save"
    $btnSave.Size = New-Object System.Drawing.Size(260, 35)
    $btnSave.Location = New-Object System.Drawing.Point(20, 95)
    $form.Controls.Add($btnSave)
    $form.AcceptButton = $btnSave

    $btnSave.Add_Click({
        $w = $txtWidth.Text.Trim()
        $h = $txtHeight.Text.Trim()

        if ($w -notmatch '^\d+$' -or $h -notmatch '^\d+$') {
            [System.Windows.Forms.MessageBox]::Show(
                "Width and height must be numbers.",
                "Validation Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        try {
            $cfg.game.width = [int]$w
            $cfg.game.height = [int]$h
            $cfg | ConvertTo-Json -Depth 4 | Set-Content $ConfigPath -Encoding UTF8

            # Run NV_Modes
            if (-not (Test-Admin)) {
                $ps = (Get-Process -Id $PID).Path
                Start-Process $ps -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$NVScript`"" -Wait
            } else {
                & $NVScript
            }

            # Generate launcher scripts
            $launchDir = Join-Path $ProjectRoot "launchers"
            if (-not (Test-Path $launchDir)) { New-Item -ItemType Directory -Path $launchDir -Force | Out-Null }
            $configBat = Join-Path $launchDir "ResolutionTool Config.bat"
            $enableBat = Join-Path $launchDir "Enable Custom Resolution.bat"
            $restoreBat = Join-Path $launchDir "Restore Native Resolution.bat"
            "@echo off`r`ncd /d `"%~dp0..`"`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\scripts\rescli.ps1`" config`r`nexit" |
                Set-Content $configBat -Encoding ASCII
            "@echo off`r`ncd /d `"%~dp0..`"`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\scripts\rescli.ps1`" game`r`npause" |
                Set-Content $enableBat -Encoding ASCII
            "@echo off`r`ncd /d `"%~dp0..`"`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0..\scripts\rescli.ps1`" native`r`npause" |
                Set-Content $restoreBat -Encoding ASCII

            [System.Windows.Forms.MessageBox]::Show(
                "Launcher files created in ResolutionTool folder.",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            $form.Close()
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    })

    [void]$form.ShowDialog()
}

function Show-Help {
    Write-Host @"
rescli - Resolution Profile Manager

Usage: rescli <command>

Commands:
  game          Set gaming resolution
  native        Restore native resolution
  fix-nvidia    Apply NV_Modes registry fix (requires admin)
  gaming-mode   Disable extra displays + set game resolution
  normal-mode   Restore displays + native resolution
  status        Show current display info
  config        Set game resolution and apply NV_Modes fix
  help          Show this message

Config: config\settings.json
"@
}

# --- Dispatch ---

switch ($Command) {
    "game"         { Invoke-Game }
    "native"       { Invoke-Native }
    "fix-nvidia"   { Invoke-FixNvidia }
    "gaming-mode"  { Invoke-GamingMode }
    "normal-mode"  { Invoke-NormalMode }
    "status"       { Invoke-Status }
    "config"       { Invoke-Config }
    "help"         { Show-Help }
}
