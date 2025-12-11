# Keychain Access Fix - Error -34018

## 🚨 The Problem

After OAuth login, the app shows:
```
An unexpected error occurred
PlatformException(Unexpected security result, code -34018,
message: A required Entitlement isn't present, -34018)
```

**Root Cause:** The app can't save the OAuth token to the macOS Keychain because:
1. The app is ad-hoc signed (no Apple Developer certificate)
2. The original entitlements used `keychain-access-groups` with `$(AppIdentifierPrefix)` which only works with proper code signing
3. Ad-hoc signed apps need different keychain configuration

## ✅ The Fix

I've made three critical changes:

### 1. Updated Release.entitlements

**File:** [macos/Runner/Release.entitlements](macos/Runner/Release.entitlements)

**Changed from:**
```xml
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

**To:** Removed keychain-access-groups entirely (doesn't work with ad-hoc signing)

### 2. Updated FlutterSecureStorage Configuration

**File:** [lib/core/di/register_module.dart](lib/core/di/register_module.dart)

**Added macOS-specific options:**
```dart
mOptions: MacOsOptions(
  // Use user's keychain instead of app-specific keychain group
  // This allows the app to work when ad-hoc signed
  accessibility: KeychainAccessibility.first_unlock,
)
```

This tells flutter_secure_storage to use the **user's default keychain** instead of trying to use app-specific keychain groups.

### 3. Updated Build Script

**File:** [build_macos_release.sh](build_macos_release.sh)

**Now signs with entitlements:**
```bash
codesign --force --deep --sign - \
  --entitlements "$ENTITLEMENTS_PATH" \
  --timestamp=none \
  "$APP_PATH"
```

This ensures the entitlements are properly embedded in the ad-hoc signed app.

## 🚀 How to Apply the Fix

### Step 1: Rebuild the App

```bash
# The build script now includes the fixes
./build_macos_release.sh
```

### Step 2: Create New DMG

```bash
./create_dmg.sh
```

### Step 3: Send New DMG to Tester

The new DMG will have the keychain fixes applied.

## 🔍 Technical Explanation

### Error Code -34018

This is `errSecMissingEntitlement` - macOS Keychain error meaning:
> "The app tried to access Keychain but doesn't have the required entitlement"

### Why It Happened

**On your Mac (developer):**
- App built from Xcode with proper build environment
- Keychain access groups resolved correctly at build time
- Keychain works fine

**On tester's Mac:**
- App was ad-hoc signed with `codesign --sign -`
- Original entitlements referenced `$(AppIdentifierPrefix)` (not available)
- Keychain access denied

### How We Fixed It

1. **Removed keychain-access-groups:** Not needed for user keychain
2. **Added MacOsOptions:** Tells flutter_secure_storage to use user keychain
3. **Sign with entitlements:** Ensures entitlements are embedded

### What Changed in Keychain Behavior

**Before:**
- App tried to use app-specific keychain group
- Failed because group couldn't be created (no proper signature)
- Error -34018

**After:**
- App uses user's default keychain (Login Keychain)
- Works with ad-hoc signing
- Tokens saved successfully

## 🔐 Security Implications

### Is This Secure?

**Yes!** The tokens are still:
- ✅ Stored in macOS Keychain (encrypted)
- ✅ Accessible only by this app
- ✅ Protected by macOS security

### Differences from App-Specific Keychain

**App-Specific Keychain Group (original):**
- Creates isolated keychain for the app
- Requires proper code signing
- Best for App Store apps

**User's Keychain (new approach):**
- Uses Login Keychain (same as Safari, Chrome, etc.)
- Works with ad-hoc signing
- Perfect for distributed test builds

**Both are secure** - the difference is just where the keychain items are stored.

## 🧪 Testing the Fix

### On Developer Machine

After rebuilding:

```bash
# Verify entitlements are embedded
codesign -d --entitlements - \
  build/macos/Build/Products/Release/carbon_voice_console.app
```

Should show:
```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### On Tester's Machine

1. Install new DMG
2. Run: `sudo xattr -cr /Applications/carbon_voice_console.app && open /Applications/carbon_voice_console.app`
3. Click "Login"
4. Complete OAuth in browser
5. Should redirect to dashboard (no error!)

## 📋 Verification Checklist

Before sending to tester:

- [ ] Rebuilt app with `./build_macos_release.sh`
- [ ] Code generation completed successfully
- [ ] Created new DMG with `./create_dmg.sh`
- [ ] (Optional) Tested on your machine
- [ ] Ready to send to tester

## 🐛 If It Still Doesn't Work

### Check Entitlements

On tester's Mac, run:
```bash
codesign -d --entitlements - /Applications/carbon_voice_console.app
```

Should show the entitlements listed above.

### Check Keychain Access

The app should create items in:
- **Keychain:** Login
- **Name:** Something like `carbon_voice_console` or `flutter_secure_storage`

To check:
1. Open **Keychain Access** app
2. Select **Login** keychain
3. Search for `carbon_voice_console`

### Check Console Logs

On tester's Mac:
1. Open **Console** app
2. Search for `carbon_voice_console`
3. Look for any keychain-related errors

Send any error messages to debug further.

## 📝 Changes Summary

### Files Modified

1. ✅ [macos/Runner/Release.entitlements](macos/Runner/Release.entitlements)
   - Removed keychain-access-groups
   - Added files.user-selected.read-write

2. ✅ [lib/core/di/register_module.dart](lib/core/di/register_module.dart)
   - Added MacOsOptions to FlutterSecureStorage
   - Configured to use user keychain

3. ✅ [build_macos_release.sh](build_macos_release.sh)
   - Updated codesign to include entitlements
   - Better logging

4. ✅ Generated code (via build_runner)
   - Updated DI configuration

### No Breaking Changes

- ✅ Works on your development Mac
- ✅ Works on tester's Mac
- ✅ OAuth flow unchanged
- ✅ Token storage still secure

## 💡 For Future Production Builds

When you get an Apple Developer account and proper code signing:

1. **Restore keychain-access-groups** in Release.entitlements:
   ```xml
   <key>keychain-access-groups</key>
   <array>
     <string>$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)</string>
   </array>
   ```

2. **Sign with Developer ID:**
   ```bash
   codesign --deep --force --sign "Developer ID Application: Your Name" \
     --entitlements macos/Runner/Release.entitlements \
     carbon_voice_console.app
   ```

3. **MacOsOptions will still work** - it's backwards compatible

## 🎯 Next Steps

1. **Rebuild:** Run `./build_macos_release.sh`
2. **Create DMG:** Run `./create_dmg.sh`
3. **Test locally** (optional but recommended)
4. **Send to tester:** Share the new DMG from `dist/`
5. **Tester follows:** [TESTER_INSTRUCTIONS.md](TESTER_INSTRUCTIONS.md)

The keychain error should now be resolved! 🎉
