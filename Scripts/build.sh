#!/bin/bash
set -e
cd "$(dirname "$0")/.."
swift build -c release
echo "Build successful."
echo "  Menu bar app: .build/release/MagSafeLEDSync"
echo "  SMC helper:   .build/release/smc-write"
