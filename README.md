# Carbon Voice Console

A Flutter admin console application for managing Carbon Voice services.

## 🚀 Quick Start

```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app with OAuth configured
./run_dev.sh

# Or run manually
flutter run -d chrome
```

**OAuth 2.0 is fully configured!** See [Quick Start Guide](docs/QUICK_START.md) for details.

## 📚 Documentation

**Comprehensive documentation is available in the [`docs/`](docs/) folder.**

### OAuth 2.0 Authentication
- **[Quick Start Guide](docs/QUICK_START.md)** - Get running in 5 minutes ⚡
- **[OAuth Setup Guide](docs/OAUTH_SETUP.md)** - Complete OAuth documentation
- **[Implementation Summary](docs/IMPLEMENTATION_SUMMARY.md)** - What's implemented

### Phase 1 Documentation
- **[Architecture Overview](docs/phase1/ARCHITECTURE.md)** - System design and patterns
- **[Setup Instructions](docs/phase1/SETUP_INSTRUCTIONS.md)** - Detailed setup guide
- **[Project Summary](docs/phase1/PROJECT_SUMMARY.md)** - Complete feature list

See [`docs/README.md`](docs/README.md) for the full documentation index.

## ✨ Features

### Phase 1: Foundation (Complete ✅)
- ✅ Clean architecture with feature-based organization
- ✅ Dependency injection using GetIt + Injectable
- ✅ Declarative routing with go_router
- ✅ State management ready with flutter_bloc
- ✅ Multi-platform support (macOS, iOS, Android, Web)

### OAuth 2.0 Authentication (Complete ✅)
- ✅ **OAuth 2.0 Authorization Code Flow with PKCE**
- ✅ **Automatic Token Refresh** - Proactive refresh 60s before expiry
- ✅ **Centralized HTTP Interceptor** - Automatic 401 handling
- ✅ **Secure Token Storage** - Using flutter_secure_storage
- ✅ **Type-Safe Error Handling** - Sealed Result<T> type
- ✅ **User-Friendly Error Messages** - Domain-agnostic mapping
- ✅ **Clean Architecture** - Domain, Data, Infrastructure layers

### Current Pages
- **Login Screen** - OAuth 2.0 authentication with Carbon Voice
- **OAuth Callback Screen** - Handles authorization redirect
- **Dashboard Screen** - Main application view (authenticated)
- **Users Screen** - User management interface (authenticated)
- **Voice Memos Screen** - Voice memo management (authenticated)
- **Settings Screen** - App settings (authenticated)

## 🏗️ Project Structure

```
lib/
  ├── main.dart           # App entry point with BLoC provider
  ├── core/
  │   ├── config/        # OAuth configuration
  │   ├── di/            # Dependency injection (GetIt + Injectable)
  │   ├── routing/       # Navigation (go_router)
  │   ├── errors/        # Failures & exceptions
  │   ├── utils/         # Result type, FailureMapper
  │   └── network/       # AuthInterceptor
  ├── common/            # Shared widgets and utilities
  ├── services/          # Service layer (API, storage, etc.)
  └── features/          # Feature modules
      ├── auth/          # OAuth 2.0 Authentication (Clean Architecture)
      │   ├── domain/    # Entities, repositories, use cases
      │   ├── data/      # Repository impl, data sources, models
      │   ├── infrastructure/  # PKCE, storage, token refresh
      │   └── presentation/    # BLoC, screens
      ├── dashboard/     # Dashboard
      ├── users/         # User management
      ├── voice_memos/   # Voice memo management
      └── settings/      # Settings
```

## 🛠️ Tech Stack

- **Flutter** 3.35.6 (stable)
- **Dart** 3.9.2
- **go_router** 14.8.1 - Declarative routing
- **flutter_bloc** 8.1.6 - State management
- **get_it** 8.3.0 + **injectable** 2.6.0 - Dependency injection
- **dio** 5.9.0 - HTTP client

## 🎯 Development

### Hot Reload
While the app is running, press `r` for hot reload or `R` for hot restart.

### Code Generation
After modifying files with `@injectable`, `@module`, or JSON serialization:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/
```

## 📱 Platform Support

- ✅ **macOS** - Native desktop app
- ✅ **iOS** - iPhone and iPad
- ✅ **Android** - Phone and tablet
- ✅ **Web** - Chrome, Safari, Firefox

## 🔗 Navigation

The app uses declarative routing with go_router:
```
/login → /dashboard → /dashboard/users
```

## 🤝 Contributing

1. Follow the clean architecture patterns
2. Use conventional commits (see [Git Commit Guide](docs/phase1/GIT_COMMIT_GUIDE.md))
3. Write tests for new features
4. Update documentation as needed

## 📄 License

[Add your license here]

## 📞 Support

For detailed documentation, troubleshooting, and guides, visit the [`docs/`](docs/) folder.

---

**Status**: Phase 1 Complete ✅ | OAuth 2.0 Complete ✅ | **Version**: 1.0.0+1


