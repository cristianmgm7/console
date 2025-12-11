#!/bin/bash

# Build macOS Release App
# This script builds a release version of the Carbon Voice Console app for macOS

set -e  # Exit on error

echo "═══════════════════════════════════════════════════════════"
echo "🚀 Building Carbon Voice Console for macOS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check which environment file to use
ENV_FILE=".env.desktop"
if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  .env.desktop not found, falling back to .env"
  ENV_FILE=".env"
fi

# Load environment variables
if [ -f "$ENV_FILE" ]; then
  echo "✅ Loading environment variables from $ENV_FILE..."
  export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
else
  echo "❌ Error: Environment file not found!"
  echo "Please ensure .env.desktop or .env exists with OAuth credentials."
  exit 1
fi

# Validate OAuth configuration
echo ""
echo "📋 OAuth Configuration:"
echo "   Redirect URL: $OAUTH_REDIRECT_URL"
echo "   Auth URL: $OAUTH_AUTH_URL"
echo "   Token URL: $OAUTH_TOKEN_URL"
echo "   API Base URL: $API_BASE_URL"
echo ""

# Warn if not using localhost
if [[ ! "$OAUTH_REDIRECT_URL" =~ ^http://localhost ]]; then
  echo "⚠️  WARNING: OAuth redirect URL is not localhost!"
  echo "   Current: $OAUTH_REDIRECT_URL"
  echo "   For desktop distribution, it should be: http://localhost/callback"
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled."
    echo ""
    echo "💡 Tip: Use .env.desktop for desktop builds:"
    echo "   cp .env.desktop .env.desktop.local"
    echo "   # Edit .env.desktop.local with your credentials"
    echo "   # Then run: ENV_FILE=.env.desktop.local ./build_macos_release.sh"
    exit 1
  fi
else
  echo "✅ Using localhost redirect (correct for desktop apps)"
  echo ""
fi

echo ""
echo "📦 Cleaning previous builds..."
flutter clean

echo ""
echo "📥 Getting dependencies..."
flutter pub get

echo ""
echo "🏗️  Building macOS app (Release mode)..."
flutter build macos --release \
  --dart-define=OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID" \
  --dart-define=OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
  --dart-define=OAUTH_REDIRECT_URL="$OAUTH_REDIRECT_URL" \
  --dart-define=OAUTH_AUTH_URL="$OAUTH_AUTH_URL" \
  --dart-define=OAUTH_TOKEN_URL="$OAUTH_TOKEN_URL" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

APP_PATH="build/macos/Build/Products/Release/carbon_voice_console.app"
ENTITLEMENTS_PATH="macos/Runner/Release.entitlements"

echo ""
echo "🔓 Fixing Gatekeeper issues..."
echo "   (Removing quarantine attributes and ad-hoc signing with entitlements)"

# Remove quarantine attribute
xattr -cr "$APP_PATH" 2>/dev/null || true

# Ad-hoc code signing with entitlements (critical for keychain access!)
echo "   Signing with entitlements..."
codesign --force --deep --sign - \
  --entitlements "$ENTITLEMENTS_PATH" \
  --timestamp=none \
  "$APP_PATH" 2>&1 | grep -v "replacing existing signature" || echo "⚠️  Could not sign (non-critical)"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Build complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📍 App location:"
echo "   $APP_PATH"
echo ""
echo "📝 Next steps:"
echo "   1. Run ./create_dmg.sh to create a DMG installer"
echo "   2. Distribute the DMG file to testers"
echo ""
