#!/bin/bash

# Fix Gatekeeper Issues for Carbon Voice Console
# Run this script to remove quarantine attributes and prepare the app for distribution

set -e

APP_PATH="build/macos/Build/Products/Release/carbon_voice_console.app"

echo "═══════════════════════════════════════════════════════════"
echo "🔓 Fixing Gatekeeper Issues"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: App not found at $APP_PATH"
  echo "Please run ./build_macos_release.sh first"
  exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""

# Remove quarantine attribute
echo "🧹 Removing quarantine attributes..."
xattr -cr "$APP_PATH"

# Ad-hoc code signing (works without developer certificate)
echo "✍️  Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_PATH"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Gatekeeper fixes applied!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📝 Next steps:"
echo "   1. Run ./create_dmg.sh to create the DMG"
echo "   2. The DMG will now work better on other Macs"
echo ""
echo "⚠️  Important for testers:"
echo "   On the OTHER Mac, they should run this command:"
echo "   sudo xattr -cr /Applications/carbon_voice_console.app"
echo ""
