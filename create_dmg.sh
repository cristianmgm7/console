#!/bin/bash

# Create DMG for macOS Distribution
# This script creates a distributable DMG file for the Carbon Voice Console app

set -e  # Exit on error

echo "═══════════════════════════════════════════════════════════"
echo "📦 Creating DMG for Carbon Voice Console"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Configuration
APP_NAME="carbon_voice_console"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="CarbonVoiceConsole-macOS"
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
DMG_OUTPUT="dist/${DMG_NAME}-v${VERSION}.dmg"
TEMP_DMG="temp.dmg"
VOLUME_NAME="Carbon Voice Console"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Error: App not found at $APP_PATH"
  echo "Please run ./build_macos_release.sh first"
  exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""

# Create dist directory
echo "📁 Creating dist directory..."
mkdir -p dist

# Remove old DMG if exists
if [ -f "$DMG_OUTPUT" ]; then
  echo "🗑️  Removing old DMG..."
  rm "$DMG_OUTPUT"
fi

# Create temporary DMG directory
echo "📦 Creating temporary DMG structure..."
TEMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DIR/"

# Copy helper script and instructions for testers
if [ -f "TESTER_INSTRUCTIONS.md" ]; then
  echo "📄 Adding tester instructions..."
  cp "TESTER_INSTRUCTIONS.md" "$TEMP_DIR/"
fi

# Create Applications symlink for easy installation
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$TEMP_DIR/Applications"

# Calculate size needed
echo "📏 Calculating DMG size..."
SIZE=$(du -sk "$TEMP_DIR" | cut -f1)
SIZE=$((SIZE + 10000))  # Add 10MB buffer

echo "💾 Creating DMG (${SIZE}KB)..."

# Create DMG
hdiutil create -srcfolder "$TEMP_DIR" \
  -volname "$VOLUME_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  -size ${SIZE}k \
  "$TEMP_DMG"

# Mount the DMG
echo "🔧 Mounting DMG for customization..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep -E '^/dev/' | sed 1q | awk '{print $1}')

# Wait for mount
sleep 2

# Set DMG window properties (optional, requires AppleScript)
echo "🎨 Customizing DMG appearance..."
echo '
   tell application "Finder"
     tell disk "'$VOLUME_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 450}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 128
           set position of item "'$APP_NAME'.app" of container window to {125, 175}
           set position of item "Applications" of container window to {375, 175}
           update without registering applications
           delay 2
           close
     end tell
   end tell
' | osascript || echo "⚠️  Could not customize DMG appearance (non-critical)"

# Sync
sync

# Unmount
echo "💿 Unmounting temporary DMG..."
hdiutil detach "$DEVICE"

# Convert to final compressed DMG
echo "🗜️  Compressing DMG..."
hdiutil convert "$TEMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_OUTPUT"

# Clean up
echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"
rm "$TEMP_DMG"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ DMG created successfully!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📍 DMG location:"
echo "   $DMG_OUTPUT"
echo ""
DMG_SIZE=$(du -h "$DMG_OUTPUT" | cut -f1)
echo "📦 Size: $DMG_SIZE"
echo ""
echo "📝 Distribution instructions:"
echo "   1. Share the DMG file with your tester"
echo "   2. Tester should double-click to mount"
echo "   3. Drag app to Applications folder"
echo "   4. First launch: Right-click → Open (to bypass Gatekeeper)"
echo ""
echo "⚠️  Important notes:"
echo "   - App is NOT code-signed (will show security warning)"
echo "   - Tester needs to right-click → Open on first launch"
echo "   - OAuth will use desktop server (localhost callback)"
echo ""
