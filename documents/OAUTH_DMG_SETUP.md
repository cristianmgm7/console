# OAuth Setup for DMG Distribution

## Problem
The macOS app was using `localhost` as the OAuth redirect URI, which doesn't work for distributed DMG files because:
1. Packaged apps don't run a local server
2. Browser redirects to `localhost` stay in the browser instead of returning to the app

## Solution
Use a **web redirect page** that bridges OAuth (HTTPS) with custom URL schemes:

1. OAuth provider redirects to: `https://yourdomain.com/auth/callback?code=...`
2. Web page automatically redirects to: `carbonvoice://auth/callback?code=...`
3. macOS routes the custom URL back to your app

This works because:
- OAuth providers require `https://` redirect URIs (security requirement)
- Custom URL schemes (`carbonvoice://`) allow apps to handle callbacks
- A simple HTML page bridges the two

## Configuration Steps

### 1. Host the Redirect Page

You need to host the `web_redirect_page.html` file on a web server at an HTTPS URL.

**Options:**

**Option A: Use GitHub Pages (Free & Easy)**
1. Create a new GitHub repository (e.g., `carbon-console-auth`)
2. Upload `web_redirect_page.html` as `index.html`
3. Enable GitHub Pages in repository settings
4. Your redirect URL will be: `https://yourusername.github.io/carbon-console-auth/`

**Option B: Use Netlify Drop (Free)**
1. Go to [drop.netlify.com](https://drop.netlify.com)
2. Drag and drop `web_redirect_page.html`
3. Get your URL: `https://random-name.netlify.app/`

**Option C: Host on Your Domain**
- Upload to your web server at `/auth/callback/` or similar
- URL: `https://yourdomain.com/auth/callback/`

### 2. Update OAuth Provider Settings

In your OAuth provider (Carbon Voice API), add this redirect URI:

```
https://yourdomain.com/auth/callback
```

Replace with your actual hosted URL. Keep existing redirect URIs (like ngrok for web).

### 3. Update .env.desktop File

Update your `.env.desktop` file to use the HTTPS redirect URL:

```bash
# OAuth Configuration for Desktop Builds
OAUTH_CLIENT_ID=your_client_id_here
OAUTH_CLIENT_SECRET=your_client_secret_here
OAUTH_REDIRECT_URL=https://yourdomain.com/auth/callback  # Your hosted redirect page
OAUTH_AUTH_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
API_BASE_URL=https://api.carbonvoice.app
```

### 4. Build the DMG

```bash
./build_macos_release.sh
./create_dmg.sh
```

The build script will now check that you're using the correct redirect URI format.

## How It Works

### OAuth Flow with Web Redirect Bridge

1. **User clicks "Login"**
   - App opens default browser with OAuth authorization URL
   - URL includes `redirect_uri=https://yourdomain.com/auth/callback`

2. **User authorizes in browser**
   - OAuth provider redirects to: `https://yourdomain.com/auth/callback?code=...&state=...`

3. **Web page receives callback**
   - Your hosted HTML page loads
   - JavaScript extracts `code` and `state` from URL
   - Automatically redirects to: `carbonvoice://auth/callback?code=...&state=...`
   - Shows manual "Open App" button as fallback

4. **macOS routes URL to app**
   - macOS sees the `carbonvoice://` scheme
   - Launches/activates your app
   - Passes the URL to `AppDelegate`

5. **App handles callback**
   - `AppDelegate.swift` receives the URL
   - Forwards it to Flutter via MethodChannel
   - `DeepLinkingService` receives the URL
   - `AuthBloc` processes the authorization code
   - Exchanges code for access token (using HTTPS redirect URI from config)
   - Saves token securely
   - Navigates to dashboard

## Technical Details

### Files Modified

#### Web Redirect Bridge
- **`web_redirect_page.html`**: HTML page that redirects OAuth callbacks to custom URL scheme

#### macOS Native
- **`macos/Runner/Info.plist`**: Registered `carbonvoice://` URL scheme
- **`macos/Runner/AppDelegate.swift`**: Added URL handler to forward deep links to Flutter

#### Flutter/Dart
- **`lib/core/services/deep_linking_service.dart`**: New service to handle deep links via MethodChannel
- **`lib/features/auth/data/repositories/oauth_repository_impl.dart`**: Updated to use configured redirect URL and removed local server
- **`lib/features/auth/presentation/bloc/auth_bloc.dart`**: Setup deep link handler for OAuth callbacks

#### Scripts
- **`build_macos_release.sh`**: Added validation for HTTPS redirect URL

### Removed Dependencies
- **`OAuthDesktopServer`**: No longer needed - removed local HTTP server implementation

## Development vs Production

### Development (using localhost)
You can still use localhost for development by:
1. Using `.env` instead of `.env.desktop`
2. Setting `OAUTH_REDIRECT_URL=http://localhost:3000/auth/callback`
3. Running `./run_dev.sh` (which starts the local server)

### Production (using HTTPS redirect bridge)
For DMG distribution:
1. Host `web_redirect_page.html` on an HTTPS server
2. Use `.env.desktop` with `OAUTH_REDIRECT_URL=https://yourdomain.com/auth/callback`
3. Build with `./build_macos_release.sh`
4. Create DMG with `./create_dmg.sh`

## Testing

### Test the Custom URL Scheme

1. **Build the app**:
   ```bash
   ./build_macos_release.sh
   ```

2. **Run the app**:
   ```bash
   open build/macos/Build/Products/Release/carbon_voice_console.app
   ```

3. **Test login flow**:
   - Click "Login"
   - Browser should open
   - After authorizing, app should activate and complete login

4. **Test deep link manually** (optional):
   ```bash
   open "carbonvoice://auth/callback?code=test&state=test"
   ```
   This should launch/activate your app.

## Troubleshooting

### App doesn't open after OAuth redirect
- **Check redirect page is accessible**: Make sure `https://yourdomain.com/auth/callback` loads in browser
- **Check Info.plist**: Verify `CFBundleURLSchemes` includes `carbonvoice`
- **Try manual link**: The redirect page shows a manual "Open App" button - try clicking it
- **Rebuild the app**: Clean build and try again

### "Invalid redirect URI" error
- The OAuth provider doesn't have your HTTPS redirect URL registered
- Make sure you added `https://yourdomain.com/auth/callback` to allowed redirect URIs
- Contact your backend team to add this redirect URI

### Redirect page doesn't work
- **Check HTTPS**: The page MUST be served over HTTPS (not HTTP)
- **Check JavaScript console**: Open browser dev tools to see any errors
- **Verify URL format**: The redirect page expects `?code=...&state=...` query parameters

### Deep link received but auth fails
- Check logs for the error
- Verify the `code` and `state` parameters are present in the URL
- Make sure token exchange is using the same redirect URI

## Support for Other Platforms

### iOS
To support iOS, you'll need to:
1. Add URL scheme to `ios/Runner/Info.plist`
2. Update `ios/Runner/AppDelegate.swift` similar to macOS

### Android
To support Android, you'll need to:
1. Add intent filter to `android/app/src/main/AndroidManifest.xml`
2. Handle deep links in MainActivity

### Web
Web continues to use the ngrok URL (no changes needed).

## Custom URL Scheme Best Practices

- **Use your brand name**: `carbonvoice://` is recognizable
- **Simple paths**: `/auth/callback` is clear and standard
- **Unique scheme**: Avoid conflicts with other apps
- **Register scheme**: No central registry needed, but document it

## Security Notes

1. **PKCE is still used**: The custom URL scheme doesn't change the security model
2. **Code verifier is stored in memory**: Secure against CSRF attacks
3. **State parameter validated**: Prevents authorization code injection
4. **Tokens stored in Keychain**: Using `flutter_secure_storage`

## Why This Approach?

**OAuth Security Requirement**: OAuth 2.0 providers require `https://` redirect URIs for security. They won't accept custom URL schemes like `carbonvoice://` directly.

**The Bridge Solution**: By using a simple HTML page hosted at an HTTPS URL, we satisfy OAuth's security requirement while still using custom URL schemes to return to the app.

**Benefits**:
- ✅ Works with any OAuth provider (uses standard HTTPS redirect)
- ✅ No backend server needed (static HTML page)
- ✅ Works in distributed DMG files
- ✅ Free hosting options (GitHub Pages, Netlify)
- ✅ Fallback manual button if auto-redirect fails

## Summary

✅ **Before**: Used `localhost:3000` → only works in development
✅ **After**: Uses HTTPS redirect → `carbonvoice://` → works in distributed DMG

The web redirect page bridges OAuth (HTTPS) with your app (custom URL scheme)!
