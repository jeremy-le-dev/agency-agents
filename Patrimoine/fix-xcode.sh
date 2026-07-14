#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "🔧 Régénération du projet Xcode..."

if ! command -v xcodegen &>/dev/null; then
  echo "Installation de XcodeGen..."
  brew install xcodegen
fi

if [[ ! -f Patrimoine/PowensConfig.plist ]]; then
  echo "❌ Patrimoine/PowensConfig.plist manquant"
  echo "   Lancez : ./configure-powens.sh patrimoine-jfr-sandbox VOTRE_CLIENT_ID VOTRE_SECRET"
  exit 1
fi

rm -rf Patrimoine.xcodeproj Patrimoine.xcworkspace
xcodegen generate

echo "✅ Projet généré : open Patrimoine.xcodeproj"
echo "   Puis ⇧⌘K → ⌘R"
