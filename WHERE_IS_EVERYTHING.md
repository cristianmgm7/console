# 📍 Where is Everything?

Quick reference for finding files in the Carbon Voice Console project.

## 📚 Documentation Files

### ✅ All documentation is in: `docs/phase1/`

| What you're looking for | Where it is |
|------------------------|-------------|
| Quick start guide | `docs/phase1/QUICKSTART.md` |
| Architecture details | `docs/phase1/ARCHITECTURE.md` |
| Setup instructions | `docs/phase1/SETUP_INSTRUCTIONS.md` |
| Project summary | `docs/phase1/PROJECT_SUMMARY.md` |
| Success guide | `docs/phase1/SUCCESS.md` |
| Current status | `docs/phase1/STATUS.md` |
| Git workflow | `docs/phase1/GIT_COMMIT_GUIDE.md` |
| Completion checklist | `docs/phase1/COMPLETION_CHECKLIST.md` |
| Setup verification | `docs/phase1/SETUP_COMPLETE.md` |
| **START HERE** | `docs/phase1/00_START_HERE.md` ⭐ |

### Documentation Index
- Main docs index: `docs/README.md`
- Project README: `README.md` (at root)

## 💻 Code Files

### Main Entry Point
- `lib/main.dart` - App entry point

### Core (Framework)
- `lib/core/di/` - Dependency injection
  - `injection.dart` - DI configuration
  - `injection.config.dart` - Generated DI code
  - `register_module.dart` - Dio HTTP client module
- `lib/core/routing/` - Navigation
  - `app_router.dart` - Router configuration
  - `app_routes.dart` - Route constants

### Features (Your App)
- `lib/features/auth/view/login_page.dart` - Login page
- `lib/features/dashboard/view/dashboard_page.dart` - Dashboard page
- `lib/features/users/view/users_page.dart` - Users page

### Shared Code
- `lib/common/widgets/` - Shared UI components
- `lib/services/` - Business logic services

### Tests
- `test/widget_test.dart` - Basic widget test

## ⚙️ Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Package dependencies |
| `analysis_options.yaml` | Linting rules |
| `build.yaml` | Code generation config |

## 📱 Platform Files

| Platform | Location |
|----------|----------|
| macOS | `macos/` |
| iOS | `ios/` |
| Android | `android/` |
| Web | `web/` |

## 🔍 Quick Find

### "I need to read the docs"
→ Go to `docs/phase1/00_START_HERE.md`

### "I want to run the app"
→ Read `docs/phase1/QUICKSTART.md`

### "I want to understand the architecture"
→ Read `docs/phase1/ARCHITECTURE.md`

### "I want to edit the Login page"
→ Open `lib/features/auth/view/login_page.dart`

### "I want to add a new route"
→ Edit `lib/core/routing/app_router.dart`

### "I want to configure dependency injection"
→ Edit `lib/core/di/register_module.dart`

### "I want to add a new package"
→ Edit `pubspec.yaml`

## 📂 Folder Structure Summary

```
carbon_voice_console/
├── README.md .................... Main README
├── docs/
│   ├── README.md ................ Docs index
│   └── phase1/ .................. All Phase 1 docs (10 files) ⭐
├── lib/
│   ├── main.dart ................ Entry point
│   ├── core/ .................... Framework (DI, routing)
│   ├── common/ .................. Shared code
│   ├── services/ ................ Business logic
│   └── features/ ................ App features
│       ├── auth/ ................ Authentication
│       ├── dashboard/ ........... Dashboard
│       └── users/ ............... User management
├── test/ ........................ Tests
├── macos/ ....................... macOS app
├── ios/ ......................... iOS app
├── android/ ..................... Android app
└── web/ ......................... Web app
```

## 💡 Tips

### If Your IDE Shows Old Paths
1. Close all open files
2. Refresh/reload the project
3. Open files from the new location: `docs/phase1/`

### If You Can't Find a Documentation File
All docs are in `docs/phase1/` - nowhere else!

### If You Want to Add New Documentation
- For Phase 1: Add to `docs/phase1/`
- For Phase 2: Create `docs/phase2/`
- Update `docs/README.md` with links

---

**Everything is organized and in the right place!** ✅

**Next**: Start with `docs/phase1/00_START_HERE.md`

