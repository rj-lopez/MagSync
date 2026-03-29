# MagSync

A macOS menu bar app that keeps your MagSafe charging LED in sync with your actual battery state and charge limits.

macOS sets a charge limit (e.g. 80%) to protect battery health, but the MagSafe LED doesn't reflect this — it stays orange even when charging has stopped. MagSync fixes that by writing the correct LED state directly to the SMC.

## LED States

| LED | Meaning |
|-----|---------|
| Green | Charge limit reached |
| Solid orange | Charging toward limit |
| Blinking orange | Heat protection (charging paused) |
| Off | Not plugged in |

## Requirements

- macOS 15 (Sequoia) or later
- Apple Silicon Mac with MagSafe 3

## Installation

1. Download `MagSync-1.0.dmg` from the [Releases](../../releases) page
2. Open the DMG and double-click `MagSync-1.0.pkg`
3. Follow the installer — you'll be asked for your password once
4. MagSync starts automatically and will launch at every login

> **First launch:** Because MagSync is not yet signed with a Developer ID, macOS Gatekeeper will warn you. Right-click the `.pkg` and choose **Open** to proceed.

## How It Works

MagSync has three main components:

- **BatteryMonitor** — listens for IOKit power state changes in real time
- **LEDController** — pure state machine that maps (battery %, charge limit, temperature) → LED state
- **SMCWriteClient** — invokes a minimal setuid helper to write the `ACLC` SMC key

Privilege separation is used: the main app runs as your user; only the tiny `smc-write` helper runs as root, and it only accepts the specific key/value pairs needed for LED control.

## Building from Source

```bash
# Build release binaries only
./Scripts/build.sh

# Build .app bundle + PKG installer + DMG (output in dist/)
./Scripts/build_app.sh
```

`build_app.sh` requires Xcode Command Line Tools (`xcode-select --install`).

## Architecture

```
Sources/
├── MagSafeLEDSync/   # Menu bar app (AppDelegate, BatteryMonitor, LEDController, ...)
├── SMCKit/           # Reusable SMC read/write library
└── smc-write/        # Setuid helper for privileged SMC writes

Resources/
├── Info.plist                    # App bundle metadata
├── Distribution.xml              # macOS Installer configuration
└── com.rjlopez.magsync.plist     # LaunchAgent for login item

Scripts/
├── build.sh                      # Build binaries only
├── build_app.sh                  # Build distributable PKG + DMG
├── install.sh                    # Developer install (no PKG)
└── pkg-scripts/postinstall       # Sets setuid on smc-write during install
```

## Acknowledgments

- [SMCKit](https://github.com/srimanachanta/SMCKit) — SMC access library
- [AsahiLinux](https://asahilinux.org/) — SMC key reverse engineering
- [Battery-Toolkit](https://github.com/mhaeuser/Battery-Toolkit) — SMC key documentation

