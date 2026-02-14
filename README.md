# ResolutionTool

Switch between custom and native display resolutions with one click.
Automatically registers custom resolutions in the NVIDIA driver.

## Installation

1. Download or clone this repository.
2. Open the `launchers` folder.
3. Double-click **ResolutionTool Config.bat** to set your game resolution.

## First-Time Setup

1. Run **ResolutionTool Config.bat** from the `launchers` folder.
2. Enter your desired game resolution (e.g. 2100 x 1440).
3. Press **Save** — the tool will:
   - Save your settings
   - Update the NVIDIA registry
   - Generate the launcher scripts

## Switching Resolutions

Open the `launchers` folder and double-click:

- **Enable Custom Resolution.bat** — switch to your game resolution
- **Restore Native Resolution.bat** — switch back to native resolution

## Advanced (CLI)

From the project root, use `rescli.bat`:

```
rescli game          Switch to game resolution
rescli native        Restore native resolution
rescli config        Open configuration window
rescli fix-nvidia    Update NVIDIA registry (admin)
rescli status        Show current resolution info
```

## Folder Overview

```
ResolutionTool/
├── rescli.bat              CLI entry point
├── README.md
├── config/
│   └── settings.json       Resolution settings
├── scripts/
│   ├── rescli.ps1          Main script
│   └── NV_Modes.ps1        NVIDIA registry updater
├── bin/
│   ├── nircmd.exe          Resolution switcher
│   └── nircmdc.exe
└── launchers/
    ├── ResolutionTool Config.bat
    ├── Enable Custom Resolution.bat
    └── Restore Native Resolution.bat
```
