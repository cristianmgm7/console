# Carbon Voice Console - Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           MyApp (main.dart)                      │
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────────┐         │
│  │  GetIt Container │◄────────│  configureDependencies│         │
│  │   (Service       │         │   (injection.dart)    │         │
│  │    Locator)      │         └──────────────────────┘         │
│  └────────┬─────────┘                                           │
│           │                                                      │
│           ├─► Dio (HTTP Client)                                 │
│           └─► AppRouter (go_router)                             │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │            MaterialApp.router                             │  │
│  │              (routerConfig: appRouter.instance)           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Navigation Layer                           │
│                      (AppRouter + Routes)                        │
│                                                                  │
│  Route: /login                                                  │
│  ├─► LoginPage                                                  │
│                                                                  │
│  Route: /dashboard                                              │
│  ├─► DashboardPage                                              │
│      │                                                           │
│      └─► Route: /dashboard/users (nested)                       │
│          └─► UsersPage                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Feature Layer                             │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Auth       │  │  Dashboard   │  │    Users     │         │
│  │              │  │              │  │              │         │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │         │
│  │  │  Bloc  │  │  │  │  Bloc  │  │  │  │  Bloc  │  │  (Future)│
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │         │
│  │              │  │              │  │              │         │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │         │
│  │  │  View  │  │  │  │  View  │  │  │  │  View  │  │  (Created)│
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │         │
│  │              │  │              │  │              │         │
│  │  ┌────────┐  │  │              │  │              │         │
│  │  │ Models │  │  │              │  │              │  (Future)│
│  │  └────────┘  │  │              │  │              │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                             │
│                        (Future: API, Storage, etc.)              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   API        │  │  Storage     │  │  Analytics   │         │
│  │   Service    │  │  Service     │  │  Service     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        External Layer                            │
│                                                                  │
│     ┌─────────┐      ┌──────────┐      ┌──────────┐           │
│     │   API   │      │ Database │      │  Cache   │           │
│     └─────────┘      └──────────┘      └──────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Navigation Flow

```
┌──────────────────────┐
│                      │
│    Login Page        │
│    (/login)          │
│                      │
│  ┌────────────────┐  │
│  │ Go to Dashboard│──┼───────────┐
│  └────────────────┘  │           │
│                      │           │
└──────────────────────┘           │
                                   ▼
                        ┌──────────────────────┐
                        │                      │
                        │   Dashboard Page     │
                        │   (/dashboard)       │
                        │                      │
            ┌───────────┤  ┌────────────────┐  │
            │           │  │  View Users    │  │
            │           │  └────────────────┘  │
            │           │           │          │
            │           │  ┌────────────────┐  │
            │           │  │ Back to Login  │  │
            │           │  └────────────────┘  │
            │           │                      │
            │           └──────────────────────┘
            │                        │
            │                        ▼
            │           ┌──────────────────────┐
            │           │                      │
            │           │    Users Page        │
            │           │    (/dashboard/users)│
            │           │                      │
            │           │  ┌────────────────┐  │
            └───────────┼──│ Back to        │  │
                        │  │ Dashboard      │  │
                        │  └────────────────┘  │
                        │                      │
                        └──────────────────────┘
```

## Dependency Injection Flow

```
┌─────────────────────────────────────────────────────────────┐
│  main.dart                                                   │
│                                                              │
│  await configureDependencies();                             │
│         │                                                    │
│         ▼                                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │ injection.dart                                      │    │
│  │                                                     │    │
│  │ @InjectableInit                                     │    │
│  │ Future<void> configureDependencies() async {       │    │
│  │   getIt.init(); // Calls generated code             │    │
│  │ }                                                   │    │
│  └──────────────────┬──────────────────────────────────┘    │
│                     │                                        │
│                     ▼                                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │ injection.config.dart (GENERATED)                   │    │
│  │                                                     │    │
│  │ extension GetItInjectableX on GetIt {               │    │
│  │   GetIt init() {                                    │    │
│  │     // Registers all dependencies                   │    │
│  │     gh.lazySingleton<Dio>(() => registerModule.dio);│    │
│  │     gh.singleton<AppRouter>(() => AppRouter());     │    │
│  │     return this;                                    │    │
│  │   }                                                 │    │
│  │ }                                                   │    │
│  └──────────────────┬──────────────────────────────────┘    │
│                     │                                        │
│                     ▼                                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │ register_module.dart                                │    │
│  │                                                     │    │
│  │ @module                                             │    │
│  │ abstract class RegisterModule {                     │    │
│  │   @lazySingleton                                    │    │
│  │   Dio get dio => Dio(BaseOptions(...));            │    │
│  │ }                                                   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Result: GetIt container has Dio and AppRouter registered  │
│                                                              │
│  Usage in MyApp:                                            │
│  final appRouter = getIt<AppRouter>();  ← Retrieves instance│
└─────────────────────────────────────────────────────────────┘
```

## Code Generation Flow

```
1. Developer writes code with annotations:
   ┌──────────────────────────────┐
   │ @injectable, @module, etc.   │
   └──────────────────────────────┘
                 │
                 ▼
2. Run build_runner:
   ┌──────────────────────────────┐
   │ flutter pub run build_runner │
   │ build --delete-conflicting   │
   └──────────────────────────────┘
                 │
                 ▼
3. injectable_generator analyzes code:
   ┌──────────────────────────────┐
   │ - Finds @injectable classes  │
   │ - Finds @module classes      │
   │ - Identifies dependencies    │
   └──────────────────────────────┘
                 │
                 ▼
4. Generates injection.config.dart:
   ┌──────────────────────────────┐
   │ - GetIt registration code    │
   │ - Extension methods          │
   │ - Dependency graph           │
   └──────────────────────────────┘
                 │
                 ▼
5. App uses generated code:
   ┌──────────────────────────────┐
   │ getIt.init()                 │
   │ getIt<Service>()             │
   └──────────────────────────────┘
```

## Routing Configuration

```
AppRouter (@singleton)
│
├── GoRouter
│   ├── initialLocation: '/login'
│   ├── debugLogDiagnostics: true
│   │
│   └── routes:
│       │
│       ├── GoRoute(path: '/login')
│       │   └── pageBuilder: MaterialPage(LoginPage)
│       │
│       └── GoRoute(path: '/dashboard')
│           ├── pageBuilder: MaterialPage(DashboardPage)
│           │
│           └── routes: [nested routes]
│               │
│               └── GoRoute(path: 'users')
│                   └── pageBuilder: MaterialPage(UsersPage)
│
└── errorBuilder: Scaffold(404 message)

Usage in pages:
  - context.go(AppRoutes.dashboard)
  - context.go(AppRoutes.users)
  - context.go(AppRoutes.login)
```

## Folder Structure Philosophy

```
lib/
│
├── core/                    ← Framework-level code
│   ├── di/                  ← Dependency injection setup
│   └── routing/             ← Navigation configuration
│
├── common/                  ← Shared across features
│   └── widgets/             ← Reusable UI components
│
├── services/                ← Business logic services
│   ├── api/                 ← API communication (future)
│   ├── storage/             ← Local storage (future)
│   └── analytics/           ← Analytics (future)
│
└── features/                ← Feature modules (isolated)
    ├── auth/
    │   ├── bloc/            ← State management
    │   ├── models/          ← Data models
    │   └── view/            ← UI pages
    │
    ├── dashboard/
    │   ├── bloc/
    │   └── view/
    │
    └── users/
        ├── bloc/
        └── view/

Benefits:
✓ Features are isolated
✓ Easy to find code
✓ Scales well
✓ Easy to test
✓ Team-friendly
```

## Data Flow (Future Implementation)

```
┌──────────────────────────────────────────────────────────┐
│                        UI Layer                           │
│                    (StatelessWidget)                      │
│                                                           │
│  LoginPage / DashboardPage / UsersPage                   │
│                                                           │
└─────────────────┬────────────────────────────────────────┘
                  │ User Actions
                  ▼
┌──────────────────────────────────────────────────────────┐
│                      BLoC Layer                           │
│                   (State Management)                      │
│                                                           │
│  AuthBloc / DashboardBloc / UsersBloc                    │
│                                                           │
│  • Receives events                                        │
│  • Calls services                                         │
│  • Emits states                                           │
│                                                           │
└─────────────────┬────────────────────────────────────────┘
                  │ Service Calls
                  ▼
┌──────────────────────────────────────────────────────────┐
│                    Service Layer                          │
│                  (Business Logic)                         │
│                                                           │
│  AuthService / UserService / DashboardService            │
│                                                           │
│  • Uses Dio for HTTP                                      │
│  • Uses Storage for persistence                           │
│  • Returns domain models                                  │
│                                                           │
└─────────────────┬────────────────────────────────────────┘
                  │ HTTP / Storage
                  ▼
┌──────────────────────────────────────────────────────────┐
│                     Data Layer                            │
│                                                           │
│  API Endpoints / Local Database / Cache                  │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Design Patterns Used

### 1. Dependency Injection Pattern
```dart
// Instead of:
class MyService {
  final api = ApiClient(); // Hard dependency
}

// We use:
@injectable
class MyService {
  final ApiClient api;
  MyService(this.api); // Injected dependency
}
```

### 2. Service Locator Pattern
```dart
// Get dependencies from central registry
final router = getIt<AppRouter>();
final api = getIt<Dio>();
```

### 3. BLoC Pattern (Prepared for)
```dart
// Business Logic Component
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // State management logic
}
```

### 4. Repository Pattern (Future)
```dart
// Abstracts data source
abstract class UserRepository {
  Future<List<User>> getUsers();
}

class UserRepositoryImpl implements UserRepository {
  final Dio dio;
  // Implementation
}
```

## Key Architectural Decisions

### ✅ Why Clean Architecture?
- Separates concerns clearly
- Makes testing easier
- Scales well with team size
- Industry standard for Flutter

### ✅ Why GetIt + Injectable?
- Type-safe dependency injection
- Code generation reduces boilerplate
- Easy to test with mocks
- Good performance

### ✅ Why go_router?
- Declarative routing (modern approach)
- Deep linking support
- Type-safe navigation
- Web support out of the box

### ✅ Why BLoC?
- Predictable state management
- Separates UI from logic
- Great testing support
- Large community

### ✅ Why Feature-First Organization?
- Features are isolated
- Easy to add/remove features
- Clear ownership
- Reduces merge conflicts

## Next Steps for Architecture Evolution

### Phase 2: State Management
- Implement BLoCs for each feature
- Add events and states
- Connect BLoCs to UI

### Phase 3: Data Layer
- Create repository interfaces
- Implement API clients
- Add local storage

### Phase 4: Testing
- Unit tests for BLoCs
- Widget tests for UI
- Integration tests for flows

### Phase 5: Advanced Features
- Error handling
- Loading states
- Offline support
- Analytics
- Monitoring

---

**Current Status**: Foundation Layer Complete ✅  
**Next Layer**: State Management (BLoC Implementation)

