#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "Building release..."
swift build -c release

echo "Installing smc-write helper (requires sudo)..."
sudo cp .build/release/smc-write /usr/local/bin/smc-write
sudo chown root:wheel /usr/local/bin/smc-write
sudo chmod 4755 /usr/local/bin/smc-write

echo ""
echo "Installed successfully."
echo "  smc-write helper: /usr/local/bin/smc-write (setuid root)"
echo "  Menu bar app:     .build/release/MagSafeLEDSync"
echo ""
echo "To start: .build/release/MagSafeLEDSync"
