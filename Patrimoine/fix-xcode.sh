#!/bin/bash
# Corrige l'erreur "Build input file cannot be found: Info.plist"
# Usage: ./fix-xcode.sh

set -euo pipefail
cd "$(dirname "$0")"

echo "🔧 Suppression de l'ancien projet Xcode (références Info.plist obsolètes)..."
rm -rf Patrimoine.xcodeproj Patrimoine.xcworkspace

if ! command -v xcodegen &>/dev/null; then
  echo "Installation de XcodeGen..."
  brew install xcodegen
fi

echo "📦 Génération du projet..."
xcodegen generate

echo ""
echo "✅ Terminé. Ouvrez Xcode :"
echo "   open Patrimoine.xcodeproj"
echo ""
echo "Puis : Product → Clean Build Folder (⇧⌘K) → Run (⌘R)"
