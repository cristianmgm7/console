# Refactoring Example: Login Screen

This document shows a before/after comparison of refactoring the login screen to use themed widgets.

## Before (Generic Material Widgets)

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        // ... listener logic ...
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to Carbon Voice',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const LoginRequested());
                  },
                  child: const Text('Login with OAuth'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Issues:**
- Generic `Text` widget with inline styles (not using theme)
- Generic `ElevatedButton` (not using themed button)
- No loading state visualization
- Generic styling doesn't match design system
- No use of glassmorphism or brand elements

---

## After (Themed Widgets)

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_gradients.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is RedirectToOAuth) {
          final uri = Uri.parse(state.url);
          if (await canLaunchUrl(uri)) {
            if (kIsWeb) {
              await launchUrl(uri, webOnlyWindowName: '_self');
            } else {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch login URL')),
              );
            }
          }
        } else if (state is Authenticated) {
          if (context.mounted) {
            context.go(AppRoutes.dashboard);
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.aura,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassContainer(
                    opacity: 0.3,
                    blurStrength: 15,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Icon
                        Icon(
                          AppIcons.sparkles,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),

                        // Welcome text
                        Text(
                          'Welcome to',
                          style: AppTextStyle.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carbon Voice Console',
                          style: AppTextStyle.displayMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your ethereal admin dashboard',
                          style: AppTextStyle.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Login button
                        AppButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                        const LoginRequested(),
                                      );
                                },
                          isLoading: isLoading,
                          fullWidth: true,
                          size: AppButtonSize.large,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(
                                AppIcons.login,
                                size: 20,
                              ),
                              const Text('Login with OAuth'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Improvements:**
- ✅ Uses `AppTextStyle` for consistent typography
- ✅ Uses `AppButton` with loading state
- ✅ Uses `GlassContainer` for glassmorphic panel
- ✅ Uses `AppGradients.aura` for background
- ✅ Uses `AppIcons` (Phosphor icons)
- ✅ Uses `AppColors` for semantic colors
- ✅ Responsive with `ConstrainedBox`
- ✅ Loading state visualization
- ✅ Brand-consistent styling
- ✅ Proper spacing using `SizedBox`

---

## Key Changes

1. **BlocListener → BlocConsumer**
   - Access to `state` in builder for loading state

2. **Generic Text → AppTextStyle**
   ```dart
   // Before
   Text('Welcome', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))

   // After
   Text('Welcome', style: AppTextStyle.displayMedium)
   ```

3. **ElevatedButton → AppButton**
   ```dart
   // Before
   ElevatedButton(onPressed: ..., child: Text('Login'))

   // After
   AppButton(
     onPressed: ...,
     isLoading: isLoading,
     fullWidth: true,
     child: Text('Login'),
   )
   ```

4. **Added Glassmorphism**
   ```dart
   GlassContainer(
     opacity: 0.3,
     blurStrength: 15,
     child: // content
   )
   ```

5. **Added Gradient Background**
   ```dart
   Container(
     decoration: BoxDecoration(gradient: AppGradients.aura),
     child: // content
   )
   ```

6. **Material Icons → Phosphor Icons**
   ```dart
   Icon(AppIcons.sparkles)  // Phosphor
   Icon(AppIcons.login)      // Phosphor
   ```

---

## Visual Result

The refactored screen now features:
- 🎨 Gradient background (lavender → pink → white)
- 🪟 Glassmorphic login panel with blur
- 🎭 Consistent typography (DM Sans)
- 🎯 Themed button with loading state
- ✨ Phosphor icons for visual consistency
- 📱 Responsive layout with max width constraint

---

## Next Files to Refactor

Based on the widget usage analysis, prioritize:

1. **Dashboard components** (highest widget count)
   - `message_card.dart`
   - `messages_action_panel.dart`
   - `app_bar_dashboard.dart`
   - `table_header_dashboard.dart`

2. **Settings screen**
   - Multiple cards
   - Switch components
   - Buttons

3. **Message components**
   - Detail views
   - Audio player sheet

Follow the same pattern: import themed widgets, replace generic Material widgets, add loading states, and ensure consistent styling.
