# Refactor Widget Modularity

You are tasked with refactoring large, complex Flutter screen widgets by breaking them down into a modular component hierarchy, improving code organization, readability, and maintainability.

## Purpose

Large screen widgets often contain multiple distinct UI sections that can be extracted into reusable components. This command helps create a clean hierarchy where screens compose components, and components compose widgets, following a clear separation of concerns.

## Directory Structure

The refactored code should follow this hierarchy:

```
lib/features/[feature]/presentation/
  - screens/          # Main screen widgets (entry points)
  - components/       # Medium-sized components (logical UI sections)
  - widgets/          # Small building blocks (individual UI elements)
```

## Evaluation Criteria

When evaluating a screen widget for refactoring:

- **Extract Components if:**
  - The screen has multiple distinct UI sections (3+ major sections)
  - Individual sections are complex enough to deserve separation
  - Sections could be reused across different screens
  - The screen exceeds 200+ lines and has complex layout logic
  - Sections have their own state management or business logic

- **Keep as Single Screen if:**
  - The screen is simple with minimal UI sections
  - The widget is under 100 lines
  - All content is tightly coupled and wouldn't benefit from separation

## Refactor Rules

**CRITICAL: All functionality must remain exactly the same. The UI output, behavior, and user experience must be identical before and after the refactor.**

When performing a refactor:

1. **Analyze Screen Structure**: Identify logical sections that form cohesive components:
   ```dart
   // Example sections in a settings screen:
   // - UserProfileSection (avatar, name, email)
   // - GeneralSettingsSection (notifications, language, theme)
   // - AccountSettingsSection (edit profile, change password)
   // - LogoutSection (logout button with confirmation)
   ```

2. **Create Component Classes**: Extract each section into its own component:
   ```dart
   // lib/features/settings/presentation/components/user_profile_section.dart
   class UserProfileSection extends StatelessWidget {
     const UserProfileSection({super.key});

     @override
     Widget build(BuildContext context) {
       return AppCard(
         child: Padding(
           padding: const EdgeInsets.all(24),
           child: Column(
             children: [
               const UserProfileAvatar(),
               const SizedBox(height: 16),
               const UserProfileInfo(),
             ],
           ),
         ),
       );
     }
   }
   ```

3. **Create Widget Classes**: Break down components into smaller widgets:
   ```dart
   // lib/features/settings/presentation/widgets/user_profile_avatar.dart
   class UserProfileAvatar extends StatelessWidget {
     const UserProfileAvatar({super.key});

     @override
     Widget build(BuildContext context) {
       return CircleAvatar(
         radius: 40,
         backgroundColor: AppColors.primary.withValues(alpha: 0.1),
         child: Icon(
           AppIcons.user,
           size: 40,
           color: AppColors.primary,
         ),
       );
     }
   }
   ```

4. **Update Screen**: Simplify the main screen to compose components:
   ```dart
   class SettingsScreen extends StatelessWidget {
     const SettingsScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: const SettingsAppBar(),
         body: ListView(
           padding: const EdgeInsets.all(24),
           children: const [
             UserProfileSection(),
             SizedBox(height: 24),
             GeneralSettingsSection(),
             SizedBox(height: 24),
             AccountSettingsSection(),
             SizedBox(height: 24),
             LogoutSection(),
           ],
         ),
       );
     }
   }
   ```

## File Creation Guidelines

1. **Component Files**: `lib/features/[feature]/presentation/components/[component_name].dart`
   - Named with `Section` suffix for major UI sections
   - Should be stateless when possible
   - May contain simple logic for their specific domain

2. **Widget Files**: `lib/features/[feature]/presentation/widgets/[widget_name].dart`
   - Named descriptively (e.g., `SettingsListTile`, `ProfileAvatar`)
   - Should be small, focused widgets
   - Prefer stateless widgets

3. **Directory Creation**: Create directories as needed:
   ```bash
   mkdir -p lib/features/settings/presentation/components
   mkdir -p lib/features/settings/presentation/widgets
   ```

## Extraction Strategy

When breaking down a complex screen:

1. **Identify Major Sections**: Look for visual/logical groupings separated by spacing, dividers, or comments
2. **Extract Components First**: Create components for major sections
3. **Extract Widgets Second**: Break down components into smaller widgets if they remain complex
4. **Maintain Dependencies**: Ensure proper import organization
5. **Preserve Styling**: Keep all styling, spacing, and theming identical

## Communication Protocol

When refactoring is complete, respond using this format:

```
Widget Modularity Refactor Complete

Changed:
- Created `UserProfileSection` component
- Created `GeneralSettingsSection` component
- Created `AccountSettingsSection` component
- Created `LogoutSection` component
- Created `UserProfileAvatar`, `UserProfileInfo`, `SettingsListTile` widgets
- Updated `SettingsScreen` to use new components

Reasoning:
- Improved maintainability by separating concerns
- Enhanced reusability of UI components
- Reduced main screen complexity from 220 to ~50 lines
- Made individual components easier to test and modify

Ready for review.
```

If unsure about extraction boundaries:
```
Widget Modularity Decision Pending

Screen: `SettingsScreen`
Potential Components:
- UserProfileSection (avatar + info)
- GeneralSettingsSection (notifications, language, theme)
- AccountSettingsSection (profile, password)
- LogoutSection (logout button)

Reason: Screen has clear visual sections that can be independently maintained
Requesting confirmation before proceeding.
```

## Examples

### Before (Complex Screen):
```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // User Profile Section
          AppCard(child: Column(children: [/* avatar, name, email */])),
          // Settings Section
          AppCard(child: Column(children: [/* notifications, language, theme */])),
          // Account Section
          AppCard(child: Column(children: [/* edit profile, change password */])),
          // Logout Section
          AppCard(child: Column(children: [/* logout button */])),
        ],
      ),
    );
  }
}
```

### After (Modular Structure):
```
lib/features/settings/presentation/
  - screens/settings_screen.dart          # Main screen composing components
  - components/
    - user_profile_section.dart           # User profile card
    - general_settings_section.dart       # General settings card
    - account_settings_section.dart       # Account settings card
    - logout_section.dart                 # Logout functionality
  - widgets/
    - user_profile_avatar.dart            # Avatar widget
    - user_profile_info.dart              # Name/email display
    - settings_list_tile.dart             # Reusable list tile
    - settings_switch_tile.dart           # Switch list tile
```

This approach creates a clear hierarchy where screens compose components, components compose widgets, and each level has a single responsibility.
