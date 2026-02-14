

# ResolutionTool

ResolutionTool allows you to switch between native and stretched game
resolutions with one click.

It is especially useful for players who cannot create custom resolutions
from NVIDIA Control Panel (common with OLED and newer monitors).

The tool automatically registers custom resolutions and lets you switch
resolutions easily before and after gaming.

---

## Features

• Add custom resolutions automatically
• One-click resolution switching
• No NVIDIA Control Panel tweaks required
• Simple launcher files for everyday use
• Designed for gaming (Valorant, FPS titles, etc.)

---

## Recommended stretched resolutions (1440p monitors)

Popular choices:

 2100 × 1440

 1566 × 1080
 
 1280 × 880

You can use any resolution you prefer.

---

## First-Time Setup

1. Open the **launchers** folder.
2. Run:

   ResolutionTool Config.bat

3. Enter your desired game resolution.
4. Press **Save**.

The tool will automatically:

• Save configuration
• Register resolution in NVIDIA driver
• Prepare launcher scripts

You only need to do this once.

---

## IMPORTANT: Restart Required

After running configuration for the first time, you MUST restart
Windows so the new resolution becomes available.

Without restarting, the custom resolution may not appear.

Restart is required only once after configuration.

---

## Switching Resolution

Open the **launchers** folder and run:

Enable Custom Resolution.bat
Switches to your custom stretched resolution.

Restore Native Resolution.bat
Returns your monitor to native resolution.

Typical usage:

• Enable custom resolution before gaming
• Restore native resolution after gaming

---

## Monitor Fix (If resolution does not appear)


If your custom resolution does not show:

1. Press **Win + X** and open **Device Manager**.
2. Expand **Monitors**.
3. If multiple monitors are listed:
   - Right-click monitors you are NOT using.
   - Select **Disable device**.
4. Restart the computer.
![alt text](app/image.png)
After restart, try enabling the custom resolution again.



## GPU Compatibility

NVIDIA GPUs: Supported
AMD GPUs: Not officially supported

---

## Notes

If NVIDIA Control Panel does not allow creating custom resolutions,
ResolutionTool automatically registers them in the driver registry.

---

Enjoy smoother stretched gameplay.
