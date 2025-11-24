# Quick Start Guide

Get the Carbon Voice Console app running in 5 minutes!

## Prerequisites

- Flutter SDK installed
- Your OAuth credentials from Carbon Voice API team

## Setup Steps

### 1. Configure Environment Variables

Your `.env` file is already configured with:

```bash
OAUTH_CLIENT_ID=HUQR5D01MSRFMFFT5uFGADjndELzoaBQKYxdr
OAUTH_CLIENT_SECRET=W5bLkvdU5PLS93rr1nK8fnogiJcqA8gAF8uNbif6UV2E8rqnxr9AOTgMzWaehDLT
OAUTH_REDIRECT_URL=https://carbonconsole.ngrok.app/auth/callback
OAUTH_AUTH_URL=https://api.carbonvoice.app/oauth/authorize
OAUTH_TOKEN_URL=https://api.carbonvoice.app/oauth/token
API_BASE_URL=https://api.carbonvoice.app
```

✅ Your credentials are already set up!

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
./run_dev.sh
```

That's it! The app will open in Chrome with OAuth fully configured.

## Quick Commands

### Run Development Server
```bash
./run_dev.sh
```

### Build for Production
```bash
./build_web.sh
```

### Run Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run Tests
```bash
flutter test
```

### Analyze Code
```bash
flutter analyze
```

## Testing OAuth Flow

1. Click **"Login with OAuth"** button
2. You'll be redirected to Carbon Voice authorization page
3. Log in with your Carbon Voice credentials
4. Authorize the app
5. You'll be redirected back and automatically logged in

## Project Structure

```
lib/
├── core/
│   ├── config/           # OAuth configuration
│   ├── errors/           # Failures & exceptions
│   ├── utils/            # Result type, FailureMapper
│   ├── network/          # AuthInterceptor
│   └── di/               # Dependency injection
│
├── features/
│   └── auth/
│       ├── domain/       # Entities, repositories, use cases
│       ├── data/         # Repository impl, data sources
│       ├── infrastructure/ # PKCE, storage, token refresh
│       └── presentation/ # BLoC, screens
│
└── main.dart            # App entry point
```

## Key Features

✅ **OAuth 2.0 with PKCE** - Secure authorization flow
✅ **Automatic Token Refresh** - No manual intervention needed
✅ **Clean Architecture** - Testable, maintainable code
✅ **Type-Safe Error Handling** - Using sealed Result<T> type
✅ **Centralized HTTP Interceptor** - Automatic 401 handling

## Next Steps

- Read [OAUTH_SETUP.md](./OAUTH_SETUP.md) for detailed documentation
- Review [OAuth plan](../thoughts/shared/plans/2025-11-23-oauth2-clean-architecture-v2.md)
- Start building your features! Authentication is ready to use

## Troubleshooting

### Can't run the script?
Make it executable:
```bash
chmod +x run_dev.sh
```

### Build errors?
Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### OAuth redirect not working?
Ensure your redirect URL is registered with Carbon Voice and matches exactly what's in `.env`.

## Environment Variables Reference

The app uses these variables (defined in `.env`):

| Variable | Purpose | Example |
|----------|---------|---------|
| `OAUTH_CLIENT_ID` | Your client identifier | `HUQR5D01...` |
| `OAUTH_CLIENT_SECRET` | Your client secret | `W5bLkvdU...` |
| `OAUTH_REDIRECT_URL` | Where OAuth redirects after auth | `https://...` |
| `OAUTH_AUTH_URL` | Authorization endpoint | `https://api.../oauth/authorize` |
| `OAUTH_TOKEN_URL` | Token endpoint | `https://api.../oauth/token` |
| `API_BASE_URL` | API base URL | `https://api.carbonvoice.app` |

## Support

Need help? Check:
- [OAUTH_SETUP.md](./OAUTH_SETUP.md) - Detailed OAuth documentation
- [Implementation Plan](../thoughts/shared/plans/2025-11-23-oauth2-clean-architecture-v2.md)
- Carbon Voice API team for OAuth server issues
