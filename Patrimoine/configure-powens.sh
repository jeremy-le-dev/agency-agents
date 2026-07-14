#!/bin/bash
# Usage: ./configure-powens.sh <domaine> [client_id] [client_secret]
# Exemple: ./configure-powens.sh monapp-sandbox 11388411 'votre-secret'

set -euo pipefail
cd "$(dirname "$0")"

DOMAIN="${1:-}"
CLIENT_ID="${2:-${POWENS_CLIENT_ID:-}}"
CLIENT_SECRET="${3:-${POWENS_CLIENT_SECRET:-}}"

if [[ -z "$DOMAIN" || -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
  echo "Usage: ./configure-powens.sh <POWENS_DOMAIN> <CLIENT_ID> <CLIENT_SECRET>"
  echo ""
  echo "Le domaine est visible dans console.powens.com :"
  echo "  URL https://monapp-sandbox.biapi.pro → domaine = monapp-sandbox"
  exit 1
fi

cat > Patrimoine/PowensConfig.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>POWENS_DOMAIN</key>
	<string>${DOMAIN}</string>
	<key>POWENS_CLIENT_ID</key>
	<string>${CLIENT_ID}</string>
	<key>POWENS_CLIENT_SECRET</key>
	<string>${CLIENT_SECRET}</string>
	<key>POWENS_REDIRECT_URI</key>
	<string>patrimoine://powens/callback</string>
</dict>
</plist>
PLIST

echo "✅ PowensConfig.plist créé pour le domaine: ${DOMAIN}"
echo "   Rebuild l'app dans Xcode (⌘R)"
