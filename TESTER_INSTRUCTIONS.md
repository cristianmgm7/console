# Carbon Voice Console - Installation Instructions for Testers

## 🚨 IMPORTANT: macOS Security Warning

This app is **not code-signed** with an Apple Developer certificate. macOS will try to block it. **This is normal and expected.** Follow the instructions below carefully.

---

## 📦 Installation Steps

### Step 1: Download the DMG
Download the `CarbonVoiceConsole-macOS-v*.dmg` file to your Mac.

### Step 2: Mount the DMG
Double-click the DMG file. A window will open showing the app.

### Step 3: Install the App
Drag **carbon_voice_console** to the **Applications** folder shortcut in the window.

### Step 4: Open the App (IMPORTANT!)

⚠️ **DO NOT just double-click the app!** It won't work. Follow these steps:

#### Option A: Terminal Command (Recommended - Most Reliable)

1. Open **Terminal** (Applications → Utilities → Terminal)

2. Copy and paste this command:
   ```bash
   sudo xattr -cr /Applications/carbon_voice_console.app && open /Applications/carbon_voice_console.app
   ```

3. Press Enter and enter your Mac password when prompted

4. The app should now open!

#### Option B: Right-Click Method

1. Go to **Applications** folder (Finder → Go → Applications)

2. Find **carbon_voice_console**

3. **Hold Control and click** on the app (or right-click)

4. Select **"Open"** from the menu

5. You'll see a warning dialog saying:
   > "carbon_voice_console" cannot be opened because the developer cannot be verified

6. Click **"Open"** anyway

7. If it still doesn't work, try Option A (Terminal) instead

#### Option C: System Settings Method

If both methods above fail:

1. Try to open the app normally (it will fail)

2. Go to **System Settings** → **Privacy & Security**

3. Scroll down to find a message about "carbon_voice_console was blocked"

4. Click **"Open Anyway"**

5. Try opening the app again

---

## 🔐 What's Happening?

macOS has a security feature called **Gatekeeper** that blocks apps not signed with an Apple Developer certificate. Since this is a test build:

- ✅ The app is safe (built by your developer)
- ❌ It's not signed with Apple's certificate (requires $99/year developer account)
- ⚠️ macOS doesn't know this, so it blocks it by default

The commands above tell macOS to trust this app anyway.

---

## 🚀 Using the App

### First Launch - Login

1. Click the **"Login"** button

2. Your **default browser** will open with the Carbon Voice login page

3. **Log in** with your Carbon Voice credentials

4. After successful login, you'll be **automatically redirected** back to the app

5. The browser tab should close, and you'll see the dashboard

### How OAuth Works

The app uses a **local OAuth server**:
- Starts a server on your computer (random port like `http://localhost:65432`)
- Opens browser for login
- Captures the authorization
- Shuts down the server

**Everything is local and secure** - no external servers involved in the OAuth flow!

---

## ✅ After First Launch

Once you've opened the app the first time using the methods above, you can:

- ✅ Double-click normally to open it
- ✅ Find it in Spotlight
- ✅ Add it to Dock

macOS will remember that you trust this app.

---

## 🐛 Troubleshooting

### Issue: "The application cannot be opened"

**Try this:**
```bash
# Open Terminal and run:
sudo xattr -cr /Applications/carbon_voice_console.app
sudo codesign --force --deep --sign - /Applications/carbon_voice_console.app
open /Applications/carbon_voice_console.app
```

### Issue: Error -34018 after login (CRITICAL)

**Symptoms:** Browser opens, you log in successfully, but then see:
> "An unexpected error occurred. PlatformException(Unexpected security result, code -34018, message: A required Entitlement isn't present, -34018)"

**This means:** The app cannot save your login token to the Keychain

**Solution:** You need an updated build with keychain fixes
- ❌ This is NOT fixable on your end
- ✅ Contact the developer - they need to rebuild the app with proper keychain entitlements
- 📅 This issue was fixed in builds created after the keychain fix update

**For developers:** See [KEYCHAIN_FIX.md](KEYCHAIN_FIX.md) for details

### Issue: OAuth login doesn't work

**Symptoms:** Browser opens, you log in, but nothing happens (no error message)

**Solutions:**

1. **Check your firewall:**
   - Go to System Settings → Network → Firewall
   - If enabled, make sure it's not blocking the app

2. **Check browser popup blocker:**
   - The redirect might be blocked
   - Allow popups for the Carbon Voice domain

3. **Try a different browser:**
   - Set a different default browser temporarily
   - Try again

4. **Check the terminal output:**
   - If you ran the app from Terminal, check for error messages

### Issue: App crashes immediately

**Try this:**
```bash
# Run from Terminal to see error messages:
/Applications/carbon_voice_console.app/Contents/MacOS/carbon_voice_console
```

Send any error messages to the developer.

### Issue: "Damage and can't be opened, move to trash"

This usually means the download was corrupted or macOS quarantine is too strict.

**Solution:**
```bash
# Remove the app
rm -rf /Applications/carbon_voice_console.app

# Re-download the DMG
# Mount it again
# Install to Applications
# Run this command:
sudo xattr -cr /Applications/carbon_voice_console.app && open /Applications/carbon_voice_console.app
```

---

## 🔒 Security & Privacy

### What permissions does the app need?

- **Network Access:** To communicate with Carbon Voice API
- **Keychain Access:** To securely store your login token
- **Local Server:** For OAuth callback (localhost only)

### Is my data safe?

- ✅ All API calls use HTTPS
- ✅ Your token is stored in macOS Keychain (encrypted)
- ✅ OAuth happens on your local machine
- ✅ No data is sent to third parties

### Why isn't this code-signed properly?

For test builds, getting an Apple Developer certificate isn't necessary. If this becomes a production app, it will be properly signed and notarized.

---

## 📝 Providing Feedback

When testing, please note:

1. **What you're testing:**
   - Login flow
   - Dashboard navigation
   - Specific features

2. **Report any issues:**
   - What you were doing
   - What happened
   - What you expected to happen
   - Screenshots if applicable

3. **macOS version:**
   - Apple menu → About This Mac
   - Report your macOS version

4. **Error messages:**
   - Copy any error messages exactly
   - Include screenshots

---

## 📞 Need Help?

If you're stuck:

1. **Try the Terminal method first** (Option A above)
2. **Send screenshots** of any error messages
3. **Contact the developer** who sent you this app

---

## 🎯 Quick Reference

### Installation (Short Version)

1. Download DMG
2. Mount DMG (double-click)
3. Drag app to Applications
4. Open Terminal, run:
   ```bash
   sudo xattr -cr /Applications/carbon_voice_console.app && open /Applications/carbon_voice_console.app
   ```
5. Use the app!

---

**Thank you for testing!** 🙏
