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

- macOS 26.4 (Tahoe) or later
- Apple Silicon Mac with MagSafe 3

## Build & Install

```bash
# Build release binaries
./Scripts/build.sh

# Install setuid helper (requires sudo)
./Scripts/install.sh
```

The install script copies `smc-write` to `/usr/local/bin/` with setuid root (`chmod 4755`), which is required to write to the SMC.

After installing, run `.build/release/MagSafeLEDSync` or add it to your Login Items.

## How It Works

MagSync has three main components:

- **BatteryMonitor** — listens for IOKit power state changes in real time
- **LEDController** — pure state machine that maps (battery %, charge limit, temperature) → LED state
- **SMCWriteClient** — invokes a minimal setuid helper to write the `ACLC` SMC key

Privilege separation is used: the main app runs as your user; only the tiny `smc-write` helper runs as root, and it only accepts the specific key/value pairs needed for LED control.

## Architecture

```
Sources/
├── MagSafeLEDSync/   # Menu bar app (AppDelegate, BatteryMonitor, LEDController, ...)
├── SMCKit/           # Reusable SMC read/write library
└── smc-write/        # Setuid helper for privileged SMC writes
```
