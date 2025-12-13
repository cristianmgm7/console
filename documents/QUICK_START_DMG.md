# Quick Start: Building DMG for Distribution

## TL;DR

Your OAuth provider doesn't accept `carbonvoice://` URLs directly. You need to:

1. **Host the redirect page** ([web_redirect_page.html](web_redirect_page.html)) on HTTPS
2. **Update your .env.desktop** to use the HTTPS URL
3. **Build the DMG**

## Step-by-Step

### 1. Host the Redirect Page (Choose One)

#### Option A: GitHub Pages (Recommended)
```bash
# Create a new repo called 'carbon-console-auth'
# Upload web_redirect_page.html as 'index.html'
# Enable GitHub Pages in Settings
# Your URL: https://yourusername.github.io/carbon-console-auth/
```

#### Option B: Netlify (Easiest)
1. Go to https://drop.netlify.com
2. Drag and drop `web_redirect_page.html`
3. Copy the URL (e.g., `https://cool-name.netlify.app/`)

### 2. Configure OAuth Provider

Add this redirect URI to your OAuth provider settings:
```
https://yourusername.github.io/carbon-console-auth/
```
(or whatever URL you got from hosting)

**Keep your existing redirect URIs!** Just add this new one.

### 3. Update .env.desktop

```bash
# Edit .env.desktop
OAUTH_REDIRECT_URL=https://yourusername.github.io/carbon-console-auth/
```

Replace with your actual hosted URL.

### 4. Build the DMG

```bash
./build_macos_release.sh
./create_dmg.sh
```

### 5. Test

1. Install the DMG on a clean Mac (or your own)
2. Open the app
3. Click "Login"
4. Browser opens for OAuth
5. After authorizing, a page opens and automatically launches your app
6. App completes login ✅

## How It Works

```
User clicks Login
  ↓
Browser opens OAuth page
  ↓
User authorizes
  ↓
Redirects to: https://yourdomain.com/auth/callback?code=...
  ↓
HTML page loads and auto-redirects to: carbonvoice://auth/callback?code=...
  ↓
macOS opens your app
  ↓
App processes auth and logs in ✅
```

## Troubleshooting

### "Invalid redirect URI" error
→ Make sure you added the HTTPS URL to your OAuth provider

### App doesn't open after OAuth
→ Check that the redirect page is accessible via HTTPS
→ Try clicking the manual "Open App" button on the redirect page

### Can't host the page
→ Ask your backend team to host it
→ Or use GitHub Pages (free, 5 minutes to set up)

## Files

- **[web_redirect_page.html](web_redirect_page.html)**: The HTML page to host
- **[OAUTH_DMG_SETUP.md](OAUTH_DMG_SETUP.md)**: Complete documentation
- **[build_macos_release.sh](build_macos_release.sh)**: Build script
- **[create_dmg.sh](create_dmg.sh)**: DMG creation script

## Need Help?

See the full documentation: [OAUTH_DMG_SETUP.md](OAUTH_DMG_SETUP.md)
