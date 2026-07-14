#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "🔧 Régénération du projet Xcode..."

if ! command -v xcodegen &>/dev/null; then
  echo "Installation de XcodeGen..."
  brew install xcodegen
fi

rm -rf Patrimoine.xcodeproj Patrimoine.xcworkspace

xcodegen generate

if [[ ! -d Patrimoine.xcodeproj ]]; then
  echo "❌ Échec : Patrimoine.xcodeproj non créé"
  exit 1
fi

echo ""
echo "✅ Projet généré avec succès"
echo "   open Patrimoine.xcodeproj"
echo ""
echo "Puis : ⇧⌘K (Clean) → ⌘R"
