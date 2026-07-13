#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen &>/dev/null; then
  echo "Installation de XcodeGen..."
  brew install xcodegen
fi

xcodegen generate
echo "✅ Projet généré : open Patrimoine.xcodeproj"
