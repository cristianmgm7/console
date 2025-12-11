# Quick Start: Build DMG for macOS Distribution

This guide will help you create a distributable DMG file for the Carbon Voice Console app.

## ⚡ TL;DR

```bash
# 1. Build the app
./build_macos_release.sh

# 2. Create the DMG
./create_dmg.sh

# 3. Share the DMG from dist/ folder
```

---

## 📋 Prerequisites

### 1. Development Environment
- macOS machine (required for building macOS apps)
- Flutter SDK installed and in PATH
- Xcode command line tools: `xcode-select --install`

### 2. OAuth Configuration

**CRITICAL**: Your OAuth provider must allow `localhost` redirects!

Check your OAuth provider settings (api.carbonvoice.app admin panel):
- ✅ Allow: `http://localhost/callback`
- ✅ Allow: `http://localhost:*/callback` (wildcard port)

Desktop apps use a local OAuth server that runs on a random port. The redirect URL will be something like `http://localhost:65432/callback` at runtime.

### 3. Environment File

The app needs OAuth credentials at build time. Two options:

#### Option A: Use .env.desktop (Recommended)

```bash
# Already created for you with correct localhost redirect
# Just verify the credentials are correct
cat .env.desktop
```

The `.env.desktop` file is pre-configured with:
```bash
OAUTH_REDIRECT_URL=http://localhost/callback  # Correct for desktop!
```

#### Option B: Use your existing .env

If your `.env` has the ngrok URL:
```bash
OAUTH_REDIRECT_URL=https://carbonconsole.ngrok.app/auth/callback
```

The build script will **warn you** but allow you to continue. The app will still work because the desktop OAuth server overrides the redirect URL at runtime.

---

## 🚀 Step-by-Step Build Process

### Step 1: Build the Release App

```bash
./build_macos_release.sh
```

This script will:
1. ✅ Load environment variables from `.env.desktop` (or `.env`)
2. ✅ Show your OAuth configuration
3. ✅ Warn if not using localhost redirect
4. ✅ Clean previous builds
5. ✅ Get Flutter dependencies
6. ✅ Build the macOS app in release mode
7. ✅ Embed OAuth credentials into the app

**Output**: `build/macos/Build/Products/Release/carbon_voice_console.app`

**Time**: ~2-5 minutes (depending on your machine)

### Step 2: Create the DMG

```bash
./create_dmg.sh
```

This script will:
1. ✅ Find the built app
2. ✅ Create a temporary DMG structure
3. ✅ Add Applications folder symlink (for easy drag-install)
4. ✅ Customize DMG appearance
5. ✅ Compress the final DMG
6. ✅ Save to `dist/` folder

**Output**: `dist/CarbonVoiceConsole-macOS-v1.0.0.dmg`

**Time**: ~30 seconds

---

## 📦 Distribution

### Share the DMG

Send the DMG file to your tester via:
- Email (if < 25MB)
- Google Drive / Dropbox
- Secure file transfer service

**File location**: `dist/CarbonVoiceConsole-macOS-v{version}.dmg`

### Installation Instructions for Tester

Send these instructions along with the DMG:

```
1. Download the DMG file
2. Double-click to mount it
3. Drag "carbon_voice_console" to the Applications folder
4. Go to Applications folder
5. RIGHT-CLICK on "carbon_voice_console" and select "Open"
6. Click "Open" in the security dialog
7. You can now use the app normally!

Important: The app is not code-signed, so you MUST right-click → Open
on first launch. After that, you can double-click normally.
```

---

## 🔍 Verification

Before sharing the DMG, test it yourself:

```bash
# 1. Open the DMG
open dist/CarbonVoiceConsole-macOS-v*.dmg

# 2. Drag the app to Applications (or Desktop for testing)

# 3. Try to run it
# Right-click → Open (first time)

# 4. Test OAuth login
# Click "Login" and verify the OAuth flow works
```

**Expected behavior**:
- ✅ App launches without crashes
- ✅ Login button opens browser
- ✅ After OAuth authorization, app receives token
- ✅ Redirects to dashboard

---

## ⚠️ Common Issues

### Issue 1: "App cannot be opened because developer cannot be verified"

**Cause**: App is not code-signed

**Solution**: Right-click → Open (instead of double-click)

### Issue 2: OAuth redirect doesn't work

**Symptom**: Browser opens, user authorizes, nothing happens

**Solution**:
1. Check OAuth provider allows `http://localhost/callback`
2. Check firewall isn't blocking the local server
3. Check [oauth_desktop_server.dart](lib/core/utils/oauth_desktop_server.dart) logs

### Issue 3: Build fails with "Unable to locate Flutter SDK"

**Solution**:
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or permanently in ~/.zshrc or ~/.bash_profile
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.zshrc
```

### Issue 4: DMG creation fails

**Symptom**: `hdiutil` errors

**Solution**:
```bash
# Ensure no previous DMG is mounted
hdiutil info | grep "carbon_voice_console"
# If found, unmount:
hdiutil detach /Volumes/CarbonVoiceConsole

# Clean and retry
rm -rf dist/
./create_dmg.sh
```

---

## 🔐 Security Notes

### What's Embedded in the DMG?

The following are **compiled into the app** (from `.env.desktop` or `.env`):
- ✅ OAuth Client ID
- ✅ OAuth Client Secret
- ✅ OAuth URLs (auth, token)
- ✅ API Base URL

**Important**: These values are **readable** by anyone who extracts them from the app binary!

### Best Practices

1. **Don't distribute publicly**: Only share with trusted testers
2. **Rotate credentials**: If DMG is leaked, regenerate OAuth credentials
3. **Use test environment**: Consider using test/staging OAuth credentials for alpha builds
4. **Add code signing**: For production, get Apple Developer certificate

---

## 📊 Build Sizes

Expected file sizes:

- **Built app**: ~50-100 MB (uncompressed)
- **DMG**: ~30-60 MB (compressed)

Actual size depends on:
- Assets included
- Dependencies
- Architecture (Universal Binary includes both Intel + Apple Silicon)

---

## 🎯 Next Steps

### For Alpha/Beta Testing
- ✅ Current setup works great!
- ✅ Share DMG with testers
- ✅ Collect feedback

### For Production Release

You'll need to:

1. **Code Signing**:
   ```bash
   # Requires Apple Developer Program ($99/year)
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name" \
     carbon_voice_console.app
   ```

2. **Notarization**:
   ```bash
   # Submit to Apple for malware scan
   xcrun notarytool submit CarbonVoiceConsole.dmg \
     --apple-id your@email.com \
     --team-id TEAMID \
     --password app-specific-password
   ```

3. **Distribution**:
   - Host on your website
   - Create Sparkle appcast for auto-updates
   - Submit to Mac App Store (optional)

---

## 📚 Additional Resources

- [DISTRIBUTION_README.md](DISTRIBUTION_README.md) - Comprehensive distribution guide
- [CLAUDE.md](CLAUDE.md) - Full codebase documentation
- [docs/OAUTH2_EXPLAINED.md](docs/OAUTH2_EXPLAINED.md) - OAuth flow details

---

## 💡 Tips

### Faster Builds

```bash
# Keep previous build
# Only rebuild changed files
flutter build macos --release  # without flutter clean
```

### Build for Specific Architecture

```bash
# Intel only (smaller DMG)
flutter build macos --release --target-platform darwin-x64

# Apple Silicon only
flutter build macos --release --target-platform darwin-arm64

# Both (default)
flutter build macos --release
```

### Custom DMG Name

Edit `create_dmg.sh`:
```bash
DMG_NAME="YourCustomName-macOS"
```

---

## 🐛 Debugging

### Enable Verbose Logging

When building:
```bash
flutter build macos --release --verbose
```

### Check Built App

```bash
# Verify app bundle
ls -lah build/macos/Build/Products/Release/carbon_voice_console.app

# Check entitlements
codesign -d --entitlements - \
  build/macos/Build/Products/Release/carbon_voice_console.app

# Check embedded credentials (careful - will show secrets!)
strings build/macos/Build/Products/Release/carbon_voice_console.app/Contents/MacOS/carbon_voice_console | grep "OAUTH_CLIENT_ID"
```

---

## ✅ Checklist

Before sharing DMG with testers:

- [ ] OAuth provider allows localhost redirects
- [ ] Built with `./build_macos_release.sh`
- [ ] Created DMG with `./create_dmg.sh`
- [ ] Tested DMG installation on your machine
- [ ] Verified OAuth login works
- [ ] Prepared installation instructions for tester
- [ ] Confirmed DMG file size is reasonable
- [ ] (Optional) Tested on another Mac

---

**Questions?** Check [DISTRIBUTION_README.md](DISTRIBUTION_README.md) or review the build scripts.
