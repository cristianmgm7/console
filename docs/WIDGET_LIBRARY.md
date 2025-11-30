# Carbon Voice Console - Widget Library

## Overview

This document provides a comprehensive guide to the themed widget library for the Carbon Voice Console. All widgets follow the "Soft Modernism" and "Ethereal Tech" design language with consistent styling, animations, and behavior.

## Quick Start

Import all widgets with a single import:

```dart
import 'package:carbon_voice_console/core/widgets/widgets.dart';
```

Or import individual categories:

```dart
import 'package:carbon_voice_console/core/widgets/buttons/app_button.dart';
import 'package:carbon_voice_console/core/widgets/cards/app_card.dart';
```

## Icon System

### AppIcons

All icons use **Phosphor Icons** for consistency. The `AppIcons` class provides semantic access to commonly used icons.

**Usage:**
```dart
Icon(AppIcons.home)
Icon(AppIcons.settings)
Icon(AppIcons.microphone)
```

**Categories:**
- **Navigation**: home, back, forward, close, menu, more, chevrons
- **Actions**: refresh, download, edit, delete, archive, share, add, remove
- **Media**: play, pause, stop, forward, rewind, microphone, audioTrack, volume
- **Status**: check, checkCircle, error, warning, info, sparkles
- **Content**: inbox, message, user, users, search, filter, settings, dashboard, notification
- **UI Elements**: calendar, clock, link, eye, logout, login

---

## Buttons

### AppButton (Primary Button)

Pill-shaped filled button with hover/press animations.

**Properties:**
- `onPressed` (VoidCallback?) - Button callback
- `child` (Widget) - Button content (usually Text)
- `size` (AppButtonSize) - small, medium, large (default: medium)
- `isLoading` (bool) - Shows loading indicator
- `fullWidth` (bool) - Stretches to full width
- `backgroundColor` (Color?) - Custom background color
- `foregroundColor` (Color?) - Custom text/icon color

**Example:**
```dart
AppButton(
  onPressed: () => print('Pressed'),
  child: const Text('Primary Action'),
)

AppButton(
  onPressed: _handleSubmit,
  size: AppButtonSize.large,
  isLoading: _isSubmitting,
  fullWidth: true,
  child: const Text('Submit'),
)
```

### AppOutlinedButton (Secondary Button)

Pill-shaped outlined button with hover fill effect.

**Properties:**
Same as AppButton, plus:
- `borderColor` (Color?) - Custom border color

**Example:**
```dart
AppOutlinedButton(
  onPressed: () => print('Cancel'),
  child: const Text('Cancel'),
)
```

### AppTextButton (Tertiary Button)

Minimal text button with hover background.

**Example:**
```dart
AppTextButton(
  onPressed: () => Navigator.pop(context),
  child: const Text('Close'),
)
```

### AppIconButton

Circular icon button with hover effects.

**Properties:**
- `icon` (IconData) - Icon to display
- `onPressed` (VoidCallback?) - Button callback
- `size` (AppIconButtonSize) - small, medium, large
- `tooltip` (String?) - Tooltip text
- `backgroundColor` (Color?) - Custom background
- `foregroundColor` (Color?) - Icon color

**Example:**
```dart
AppIconButton(
  icon: AppIcons.close,
  onPressed: () => Navigator.pop(context),
  tooltip: 'Close',
)

AppIconButton(
  icon: AppIcons.refresh,
  onPressed: _handleRefresh,
  size: AppIconButtonSize.large,
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.onPrimary,
)
```

---

## Cards

### AppCard

Standard card with shadow and rounded corners.

**Properties:**
- `child` (Widget) - Card content
- `padding` (EdgeInsetsGeometry?) - Internal padding
- `backgroundColor` (Color?) - Background color
- `borderRadius` (BorderRadius?) - Custom border radius
- `elevation` (bool) - Show shadow (default: true)

**Example:**
```dart
AppCard(
  child: Column(
    children: [
      Text('Card Title', style: AppTextStyle.titleMedium),
      const SizedBox(height: 8),
      Text('Card content goes here'),
    ],
  ),
)
```

### AppOutlinedCard

Card with border, no shadow.

**Example:**
```dart
AppOutlinedCard(
  borderColor: AppColors.primary,
  child: Text('Outlined card content'),
)
```

### AppInteractiveCard

Card with tap/hover interactions and animations.

**Properties:**
Same as AppCard, plus:
- `onTap` (VoidCallback?) - Tap callback
- `onLongPress` (VoidCallback?) - Long press callback
- `hoverElevation` (bool) - Enhanced shadow on hover

**Example:**
```dart
AppInteractiveCard(
  onTap: () => _openDetails(item),
  child: Row(
    children: [
      Icon(AppIcons.message),
      const SizedBox(width: 12),
      Text(item.title),
    ],
  ),
)
```

---

## Containers

### AppContainer

Basic themed container with consistent styling.

**Example:**
```dart
AppContainer(
  padding: const EdgeInsets.all(16),
  backgroundColor: AppColors.background,
  child: Text('Container content'),
)
```

### GlassContainer

Glassmorphism effect container with backdrop blur.

**Properties:**
- `child` (Widget) - Content
- `padding` (EdgeInsetsGeometry?) - Internal padding
- `opacity` (double) - Glass opacity (default: 0.5)
- `borderRadius` (BorderRadius?) - Custom border radius
- `blurStrength` (double) - Blur intensity (default: 10.0)

**Example:**
```dart
GlassContainer(
  opacity: 0.3,
  blurStrength: 15,
  child: Column(
    children: [
      Text('Glassmorphic Panel'),
      // ...
    ],
  ),
)
```

### AppPillContainer

Pill-shaped container for tags/chips.

**Example:**
```dart
AppPillContainer(
  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
  foregroundColor: AppColors.primary,
  child: const Text('Active'),
)
```

---

## Progress Indicators

### AppProgressIndicator

Themed circular or linear progress indicator.

**Properties:**
- `type` (AppProgressIndicatorType) - circular or linear
- `size` (AppProgressIndicatorSize) - small, medium, large
- `value` (double?) - Progress value (0.0 - 1.0), null for indeterminate
- `color` (Color?) - Progress color
- `backgroundColor` (Color?) - Track color

**Examples:**
```dart
// Indeterminate circular
AppProgressIndicator()

// Determinate linear
AppProgressIndicator(
  type: AppProgressIndicatorType.linear,
  value: 0.65,
  size: AppProgressIndicatorSize.large,
)

// Small circular with custom color
AppProgressIndicator(
  size: AppProgressIndicatorSize.small,
  color: AppColors.success,
)
```

---

## Interactive Elements

### AppCheckbox

Themed checkbox with animations.

**Properties:**
- `value` (bool) - Checked state
- `onChanged` (ValueChanged<bool>?) - Change callback
- `activeColor` (Color?) - Checked color
- `checkColor` (Color?) - Checkmark color

**Example:**
```dart
AppCheckbox(
  value: _isSelected,
  onChanged: (value) => setState(() => _isSelected = value),
)
```

### AppSwitch

Themed toggle switch with smooth animations.

**Properties:**
- `value` (bool) - Switch state
- `onChanged` (ValueChanged<bool>?) - Change callback
- `activeColor` (Color?) - Active color

**Example:**
```dart
AppSwitch(
  value: _notificationsEnabled,
  onChanged: (value) {
    setState(() => _notificationsEnabled = value);
  },
)
```

---

## Migration Guide

### Before (Generic Material Widgets):

```dart
ElevatedButton(
  onPressed: _handleSubmit,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
  ),
  child: const Text('Submit'),
)
```

### After (Themed Widgets):

```dart
AppButton(
  onPressed: _handleSubmit,
  child: const Text('Submit'),
)
```

---

## Common Patterns

### Button Row (Primary + Secondary)
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  spacing: 12,
  children: [
    AppOutlinedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    AppButton(
      onPressed: _handleSave,
      child: const Text('Save'),
    ),
  ],
)
```

### Loading State
```dart
AppButton(
  onPressed: _isLoading ? null : _handleSubmit,
  isLoading: _isLoading,
  child: const Text('Submit'),
)
```

### Icon Button with Tooltip
```dart
AppIconButton(
  icon: AppIcons.refresh,
  onPressed: _handleRefresh,
  tooltip: 'Refresh data',
)
```

### Interactive List Item
```dart
AppInteractiveCard(
  onTap: () => _openDetails(item),
  child: ListTile(
    leading: Icon(AppIcons.message),
    title: Text(item.title),
    trailing: Icon(AppIcons.chevronRight),
  ),
)
```

### Status Chip
```dart
AppPillContainer(
  backgroundColor: AppColors.success.withValues(alpha: 0.1),
  foregroundColor: AppColors.success,
  child: const Text('Complete'),
)
```

### Glass Panel
```dart
GlassContainer(
  opacity: 0.4,
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(
          'Welcome',
          style: AppTextStyle.displayMedium,
        ),
        const SizedBox(height: 16),
        Text('Your ethereal dashboard'),
      ],
    ),
  ),
)
```

---

## Design Tokens Reference

All widgets automatically use the theme tokens from:

- **Colors**: `AppColors` ([app_colors.dart](../lib/core/theme/app_colors.dart))
- **Typography**: `AppTextStyle` ([app_text_style.dart](../lib/core/theme/app_text_style.dart))
- **Borders**: `AppBorders` ([app_borders.dart](../lib/core/theme/app_borders.dart))
- **Shadows**: `AppShadows` ([app_shadows.dart](../lib/core/theme/app_shadows.dart))
- **Spacing**: `AppDimensions` ([app_dimensions.dart](../lib/core/theme/app_dimensions.dart))
- **Animations**: `AppAnimations` ([app_animations.dart](../lib/core/theme/app_animations.dart))
- **Icons**: `AppIcons` ([app_icons.dart](../lib/core/theme/app_icons.dart))

---

## Widget Inventory

### ✅ Completed

- [x] **Buttons**: AppButton, AppOutlinedButton, AppTextButton, AppIconButton
- [x] **Cards**: AppCard, AppOutlinedCard, AppInteractiveCard
- [x] **Containers**: AppContainer, GlassContainer, AppPillContainer
- [x] **Indicators**: AppProgressIndicator (circular + linear)
- [x] **Interactive**: AppCheckbox, AppSwitch
- [x] **Icons**: AppIcons (60+ Phosphor icons)

### 🚧 Pending (Future Enhancements)

- [ ] **Inputs**: AppTextField, AppTextArea, AppDropdown, AppSearchField
- [ ] **Feedback**: AppSnackbar, AppDialog, AppBottomSheet, AppToast
- [ ] **Navigation**: AppNavItem, AppTabBar, AppBreadcrumbs
- [ ] **Advanced**: AppChip, AppBadge, AppTooltip, AppSlider

---

## Best Practices

1. **Always use themed widgets** instead of generic Material widgets
2. **Use AppIcons** instead of Material Icons for consistency
3. **Leverage size variants** (small, medium, large) for responsive design
4. **Use semantic colors** from AppColors (success, error, warning, info)
5. **Prefer AppProgressIndicator** over raw CircularProgressIndicator
6. **Use GlassContainer** for overlay panels and modals
7. **Use AppInteractiveCard** for clickable list items
8. **Use AppPillContainer** for status badges and tags

---

## Testing

All widgets have been designed with:
- ✅ Hover states
- ✅ Press animations
- ✅ Disabled states
- ✅ Loading states
- ✅ Accessibility (tooltips, semantic labels)
- ✅ Responsive sizing

---

## Next Steps

To apply these widgets throughout your app:

1. **Import the widget library** in your feature files
2. **Replace Material widgets** with themed equivalents
3. **Test visual consistency** across all screens
4. **Run the app** to verify animations and interactions

Example refactor:
```dart
// Old
import 'package:flutter/material.dart';

// New
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
```

---

**Questions or Issues?**
See [CLAUDE.md](./CLAUDE.md) for full project context and architecture patterns.
