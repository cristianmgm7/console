#!/bin/bash

# Helper script for testers to open the app on their Mac
# This removes Gatekeeper restrictions and opens the app

echo "═══════════════════════════════════════════════════════════"
echo "🔓 Carbon Voice Console - Gatekeeper Bypass"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "This script will:"
echo "  1. Remove quarantine attributes from the app"
echo "  2. Add ad-hoc code signature"
echo "  3. Open the app"
echo ""
echo "You'll need to enter your Mac password."
echo ""

APP_PATH="/Applications/carbon_voice_console.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: App not found at $APP_PATH"
  echo ""
  echo "Please install the app first:"
  echo "  1. Double-click the DMG file"
  echo "  2. Drag carbon_voice_console to Applications folder"
  echo "  3. Run this script again"
  exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""

# Ask for confirmation
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo "🧹 Removing quarantine attributes..."
sudo xattr -cr "$APP_PATH"

echo "✍️  Adding ad-hoc code signature..."
sudo codesign --force --deep --sign - "$APP_PATH"

echo ""
echo "🚀 Opening app..."
open "$APP_PATH"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Done!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "The app should now be open."
echo ""
echo "ℹ️  You only need to run this script ONCE."
echo "   After this, you can open the app normally."
echo ""
