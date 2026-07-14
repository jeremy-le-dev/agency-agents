#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen &>/dev/null; then
  echo "Installation de XcodeGen..."
  brew install xcodegen
fi

# Supprime l'ancien .xcodeproj pour éviter les références Info.plist obsolètes
rm -rf Patrimoine.xcodeproj Patrimoine.xcworkspace

xcodegen generate
echo "✅ Projet généré : open Patrimoine.xcodeproj"
