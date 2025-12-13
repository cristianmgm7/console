# Carbon Voice Console - macOS Distribution Guide

## 🚀 Quick Start for Developers

### Prerequisites
- macOS development machine
- Flutter SDK installed
- Xcode command line tools
- `.env` file with OAuth credentials

### Building the DMG

```bash
# 1. Build the release app
./build_macos_release.sh

# 2. Create the DMG
./create_dmg.sh
```

The DMG will be created in the `dist/` folder.

---

## 📦 For Testers - Installation Instructions

### Installing the App

1. **Download** the DMG file (e.g., `CarbonVoiceConsole-macOS-v1.0.0.dmg`)

2. **Double-click** the DMG file to mount it

3. **Drag** the Carbon Voice Console app to the Applications folder

4. **First Launch** (Important!):
   - Go to Applications folder
   - **Right-click** on Carbon Voice Console
   - Select **"Open"**
   - Click **"Open"** in the security dialog

   ⚠️ **Why?** The app is not code-signed, so macOS Gatekeeper will block it if you just double-click. Using right-click → Open bypasses this restriction.

5. **Subsequent Launches**: You can now double-click normally

### Using the App

The app uses OAuth 2.0 for authentication. When you click "Login":

1. A local server will start on your computer (random port)
2. Your default browser will open with the OAuth login page
3. After authorizing, you'll be redirected back to the app
4. The browser tab will close automatically

**Everything works offline** after initial authentication - the OAuth flow happens on your local machine.

---

## 🔧 OAuth Configuration (For Developers)

### Important: Desktop vs Web OAuth

**Desktop apps** use a different OAuth flow than web apps:

- **Web**: Redirect to `https://your-domain.com/auth/callback`
- **Desktop**: Redirect to `http://localhost:{random-port}/callback`

### Setting Up OAuth Provider

You need to configure your OAuth provider to accept localhost redirects:

1. **Go to your OAuth provider settings** (e.g., Carbon Voice API admin panel)

2. **Add redirect URI**: `http://localhost/callback`
   - Most providers accept wildcards or localhost without port
   - Some require specific ports (e.g., `http://localhost:*`)

3. **Update `.env` file** (for building):
   ```bash
   OAUTH_REDIRECT_URL=http://localhost/callback
   ```

### Current Configuration

The current `.env` uses:
```
OAUTH_REDIRECT_URL=https://carbonconsole.ngrok.app/auth/callback
```

This works for **web development with ngrok** but **NOT for desktop distribution**.

### How It Works

The app includes a **desktop OAuth server** ([oauth_desktop_server.dart](lib/core/utils/oauth_desktop_server.dart)) that:

1. Starts a local HTTP server on a random port
2. Updates the redirect URL to `http://localhost:{port}/callback`
3. Opens the browser with the OAuth URL
4. Captures the OAuth callback
5. Exchanges the code for a token
6. Shuts down the server

**This all happens automatically** - no configuration needed by the tester!

---

## 🛠️ Technical Details

### Build Configuration

- **Flutter Version**: 3.35.6
- **Build Mode**: Release
- **Architecture**: Universal Binary (Intel + Apple Silicon)
- **Entitlements**:
  - Network client/server access (for OAuth)
  - Keychain access (for secure token storage)
  - App sandbox: **Disabled** (required for local server)

### Security Considerations

#### Code Signing

The app is **NOT code-signed** because:
- Requires Apple Developer Program membership ($99/year)
- Requires certificates and provisioning profiles
- Not necessary for internal testing

**Implications**:
- macOS Gatekeeper will warn users on first launch
- Users must right-click → Open to bypass
- App cannot be distributed on Mac App Store

**For production distribution**, you should:
1. Enroll in Apple Developer Program
2. Get a Developer ID certificate
3. Code sign the app: `codesign --deep --force --verify --verbose --sign "Developer ID" app.app`
4. Notarize with Apple: `xcrun notarytool submit`

#### App Sandbox

The app **disables** app sandbox in [Release.entitlements](macos/Runner/Release.entitlements):
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

**Why?** The OAuth desktop server needs to:
- Start a local HTTP server on a random port
- Accept incoming connections

**Security implications**:
- App has full system access
- Not suitable for Mac App Store
- Fine for internal/enterprise distribution

### File Structure

```
dist/
  └── CarbonVoiceConsole-macOS-v1.0.0.dmg   # Distributable installer

build/macos/Build/Products/Release/
  └── carbon_voice_console.app              # Compiled app bundle
```

### Environment Variables Embedded

The following environment variables are **compiled into the app** (from `.env`):
- `OAUTH_CLIENT_ID`
- `OAUTH_CLIENT_SECRET`
- `OAUTH_REDIRECT_URL`
- `OAUTH_AUTH_URL`
- `OAUTH_TOKEN_URL`
- `API_BASE_URL`

**Important**: If you change these, you must rebuild the app!

---

## 📋 Troubleshooting

### "App cannot be opened because the developer cannot be verified"

**Solution**: Right-click the app → Open → Open (see Installation Instructions above)

### OAuth redirect doesn't work

**Symptoms**: Browser opens, you authorize, but nothing happens

**Possible causes**:
1. OAuth provider doesn't allow localhost redirects
   - **Fix**: Update provider settings to allow `http://localhost/*`

2. Firewall blocking local server
   - **Fix**: Allow incoming connections for the app in System Settings → Security & Privacy → Firewall

3. Browser blocking the redirect
   - **Fix**: Check browser console for errors

### App crashes on launch

**Symptoms**: App opens and immediately closes

**Possible causes**:
1. Missing environment variables
   - **Check**: App was built with `./build_macos_release.sh` (includes .env)

2. Entitlements issue
   - **Check**: [Release.entitlements](macos/Runner/Release.entitlements) has sandbox disabled

### Token not persisting

**Symptoms**: Have to log in every time

**Possible causes**:
1. Keychain access denied
   - **Fix**: Grant keychain access when prompted

2. App bundle ID changed
   - **Check**: Keychain items are scoped to bundle ID

---

## 🔐 Security Best Practices

### For Distribution

1. **Don't include secrets in the DMG**
   - Environment variables are embedded at build time
   - Ensure `.env` has production credentials

2. **Use HTTPS for all API calls**
   - Current config uses `https://api.carbonvoice.app` ✅

3. **OAuth credentials rotation**
   - If credentials are compromised, regenerate and rebuild

4. **Distribute via secure channel**
   - Use encrypted email, secure file sharing, etc.
   - Don't post DMG publicly with embedded secrets

### For Testers

1. **Verify the DMG source**
   - Only install DMGs from trusted developers

2. **Check the app signature** (if signed):
   ```bash
   codesign -dv --verbose=4 /Applications/carbon_voice_console.app
   ```

3. **Review permissions**
   - App should only request network and keychain access

---

## 📞 Support

### For Developers
- Check [CLAUDE.md](CLAUDE.md) for codebase documentation
- Review [docs/OAUTH2_EXPLAINED.md](docs/OAUTH2_EXPLAINED.md) for OAuth flow details
- See [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md) for API reference

### For Testers
Contact the developer who sent you the DMG for support.

---

## 📝 Version History

### v1.0.0 (Current)
- Initial release
- OAuth 2.0 authentication
- Dashboard with side navigation
- User management
- Workspace management
- Conversation management
- Audio playback
- Voice memos

---

## 🚀 Future Enhancements

### Code Signing & Notarization
- Enroll in Apple Developer Program
- Obtain Developer ID certificate
- Implement automated signing in build script
- Add notarization step

### Auto-Update
- Implement Sparkle framework
- Host appcast.xml for update checks
- Add in-app update notifications

### Enhanced Distribution
- Create installer with custom welcome screen
- Add license agreement page
- Include uninstaller script

---

## 📄 License

Copyright © 2024 Carbon Voice. All rights reserved.
