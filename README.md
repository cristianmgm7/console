# Carbon Voice Console

A Flutter admin console application for managing Carbon Voice services.

## Phase 1: Project Setup

This is a greenfield Flutter project with the following features:

### Architecture
- Clean architecture with feature-based organization
- Dependency injection using GetIt + Injectable
- Routing with go_router
- State management with flutter_bloc

### Current Features
- Login page (placeholder)
- Dashboard page
- Users management page

### Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate dependency injection code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
  ├── core/          # Core functionality (DI, routing, constants)
  ├── common/        # Shared widgets and utilities
  ├── services/      # Service layer (API, storage, etc.)
  └── features/      # Feature modules
      ├── auth/      # Authentication
      ├── dashboard/ # Dashboard
      └── users/     # User management
```

