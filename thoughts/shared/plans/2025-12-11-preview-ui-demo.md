# Public Conversation Preview - UI Demo Implementation Plan

## Overview

This plan implements a **UI-only demonstration** of the public conversation preview feature. It shows the complete user experience flow (message selection → preview composer → confirmation) using local state management and mock data, without requiring backend integration.

**Purpose**: Demonstrate the feature to stakeholders and gather UI/UX feedback before backend implementation decisions are finalized.

**Full Implementation**: See [`2025-12-09-public-conversation-previews.md`](2025-12-09-public-conversation-previews.md) for the complete backend-integrated implementation plan (ready to execute once backend is decided).

## Current State Analysis

### What Exists:
- **Message Selection**: `MessageSelectionCubit` manages multi-select state ([message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart))
- **Conversation Data**: Full conversation entities with title, description, imageUrl ([conversation_entity.dart](lib/features/conversations/domain/entities/conversation_entity.dart))
- **Routing**: `go_router` with `ShellRoute` for authenticated routes ([app_router.dart](lib/core/routing/app_router.dart))
- **State Management**: BLoC/Cubit patterns established

### What's Missing:
- UI screens for preview composer and confirmation
- Local state management for preview metadata
- Route definitions for preview flow
- Dashboard integration button

### Key Constraint:
**No backend integration** - This is intentional. All data is local/mock until backend architecture is decided.

## Desired End State

### Specification:
1. **Dashboard Integration**: "Publish Preview" button appears when 3-5 messages are selected
2. **Preview Composer Screen**: Modal/screen to enter title, description, and optional cover image URL
3. **Form Validation**: Real-time validation for required fields and character limits
4. **Mock Success Flow**: Simulated "publish" operation that transitions to confirmation screen
5. **Confirmation Screen**: Display generated mock preview URL with copy functionality
6. **Complete User Journey**: Users can experience the full flow from selection to sharing

### Verification Criteria:

#### Automated Verification:
- [ ] Build compiles without errors: `flutter analyze`
- [ ] No lint errors: `flutter analyze`
- [ ] All routes resolve correctly (no routing errors on navigation)
- [ ] Widget tests pass for form validation: `flutter test`

#### Manual Verification:
- [ ] "Publish Preview" button appears when selecting messages
- [ ] Button is disabled when <3 or >5 messages selected
- [ ] Clicking button navigates to composer screen
- [ ] Composer pre-fills with conversation title/description/image
- [ ] Title field validates (required, max 100 chars)
- [ ] Description field validates (required, max 200 chars)
- [ ] Cover image URL validates format
- [ ] Selection counter displays correctly (3/5 messages)
- [ ] "Publish" button disabled when form invalid
- [ ] "Publish" shows mock loading state (1 second delay)
- [ ] Success navigates to confirmation screen
- [ ] Confirmation shows mock preview URL
- [ ] Copy button copies URL to clipboard
- [ ] Back button returns to dashboard
- [ ] Selection clears after mock publish

## What We're NOT Doing

- **No Backend Integration**: No API calls, no real data persistence
- **No Domain/Data Layers**: Skipping repository, use case, DTO layers
- **No Real Preview Generation**: Mock URL only, no actual preview page
- **No Image Upload**: URL input only (consistent with full plan)
- **No Preview Analytics**: No tracking or metrics
- **No Preview Management**: No edit/delete functionality
- **No Automated Tests**: Widget tests only (no BLoC/repository tests)

## Implementation Approach

### Strategy:
1. **UI-First**: Focus on screens, forms, navigation, and user experience
2. **Local State Only**: Use Cubit for form state, simulated delays for "publishing"
3. **Mock Data**: Generate fake preview URLs for demonstration
4. **Reusable Patterns**: Follow existing UI conventions (AppButton, AppColors, etc.)
5. **Migration Ready**: Structure code to easily swap in real BLoC/repository later

### Architecture (Simplified):
```
lib/features/preview/
  └── presentation/
      ├── cubit/
      │   ├── preview_composer_cubit.dart        # Form state management
      │   └── preview_composer_state.dart
      ├── screens/
      │   ├── preview_composer_screen.dart       # Metadata entry screen
      │   └── preview_confirmation_screen.dart   # Success/sharing screen
      └── widgets/
          ├── message_selection_counter.dart     # "3/5 selected" display
          ├── preview_metadata_form.dart         # Title/desc inputs
          └── preview_share_panel.dart           # URL copy/share
```

**Note**: No domain or data layers. When backend is ready, add those layers per the full plan.

---

## Phase 1: Local State Management (Cubit)

### Overview
Create a Cubit to manage preview composer form state locally. This handles validation, field updates, and form submission without any API calls.

### Changes Required:

#### 1. Preview Composer State

**File**: `lib/features/preview/presentation/cubit/preview_composer_state.dart`
**Changes**: Create new file with form state

```dart
import 'package:equatable/equatable.dart';

/// State for the preview composer form (UI-only demo version)
class PreviewComposerState extends Equatable {
  const PreviewComposerState({
    this.title = '',
    this.description = '',
    this.coverImageUrl,
    this.titleError,
    this.descriptionError,
    this.coverImageUrlError,
    this.isPublishing = false,
    this.mockPreviewUrl,
  });

  final String title;
  final String description;
  final String? coverImageUrl;
  final String? titleError;
  final String? descriptionError;
  final String? coverImageUrlError;
  final bool isPublishing;
  final String? mockPreviewUrl;

  bool get isValid =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      titleError == null &&
      descriptionError == null &&
      coverImageUrlError == null;

  bool get hasErrors =>
      titleError != null || descriptionError != null || coverImageUrlError != null;

  PreviewComposerState copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
    String? titleError,
    String? descriptionError,
    String? coverImageUrlError,
    bool? isPublishing,
    String? mockPreviewUrl,
  }) {
    return PreviewComposerState(
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      titleError: titleError,
      descriptionError: descriptionError,
      coverImageUrlError: coverImageUrlError,
      isPublishing: isPublishing ?? this.isPublishing,
      mockPreviewUrl: mockPreviewUrl ?? this.mockPreviewUrl,
    );
  }

  PreviewComposerState clearErrors() {
    return PreviewComposerState(
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      isPublishing: isPublishing,
      mockPreviewUrl: mockPreviewUrl,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        coverImageUrl,
        titleError,
        descriptionError,
        coverImageUrlError,
        isPublishing,
        mockPreviewUrl,
      ];
}
```

#### 2. Preview Composer Cubit

**File**: `lib/features/preview/presentation/cubit/preview_composer_cubit.dart`
**Changes**: Create new file with Cubit implementation

```dart
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class PreviewComposerCubit extends Cubit<PreviewComposerState> {
  PreviewComposerCubit(this._logger) : super(const PreviewComposerState());

  final Logger _logger;

  static const int maxDescriptionLength = 200;

  /// Initialize form with conversation data
  void initialize({
    required String conversationTitle,
    String? conversationDescription,
    String? conversationImageUrl,
  }) {
    _logger.d('Initializing preview composer');
    emit(PreviewComposerState(
      title: conversationTitle,
      description: conversationDescription ?? '',
      coverImageUrl: conversationImageUrl,
    ));
  }

  /// Update title field
  void updateTitle(String title) {
    String? error;

    if (title.trim().isEmpty) {
      error = 'Title is required';
    } else if (title.trim().length > 100) {
      error = 'Title must be 100 characters or less';
    }

    emit(state.copyWith(
      title: title,
      titleError: error,
    ));
  }

  /// Update description field
  void updateDescription(String description) {
    String? error;

    if (description.trim().isEmpty) {
      error = 'Description is required';
    } else if (description.trim().length > maxDescriptionLength) {
      error = 'Description must be $maxDescriptionLength characters or less';
    }

    emit(state.copyWith(
      description: description,
      descriptionError: error,
    ));
  }

  /// Update cover image URL field
  void updateCoverImageUrl(String? url) {
    String? error;

    if (url != null && url.trim().isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Invalid URL format';
      }
    }

    emit(state.copyWith(
      coverImageUrl: url?.trim(),
      coverImageUrlError: error,
    ));
  }

  /// Validate all fields
  bool validate() {
    String? titleError;
    String? descriptionError;

    if (state.title.trim().isEmpty) {
      titleError = 'Title is required';
    } else if (state.title.trim().length > 100) {
      titleError = 'Title must be 100 characters or less';
    }

    if (state.description.trim().isEmpty) {
      descriptionError = 'Description is required';
    } else if (state.description.trim().length > maxDescriptionLength) {
      descriptionError =
          'Description must be $maxDescriptionLength characters or less';
    }

    if (titleError != null || descriptionError != null) {
      emit(state.copyWith(
        titleError: titleError,
        descriptionError: descriptionError,
      ));
      return false;
    }

    return true;
  }

  /// Mock publish operation (simulates API call)
  Future<void> mockPublish({
    required String conversationId,
    required List<String> messageIds,
  }) async {
    _logger.i('Mock publishing preview for conversation: $conversationId');
    _logger.d('Selected message IDs: ${messageIds.join(", ")}');

    // Set publishing state
    emit(state.copyWith(isPublishing: true));

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate mock preview URL
    final mockUrl = 'https://carbonvoice.app/preview/demo_${DateTime.now().millisecondsSinceEpoch}';

    _logger.i('Mock preview published: $mockUrl');

    // Update state with mock URL
    emit(state.copyWith(
      isPublishing: false,
      mockPreviewUrl: mockUrl,
    ));
  }

  /// Reset form state
  void reset() {
    _logger.d('Resetting preview composer');
    emit(const PreviewComposerState());
  }
}
```

#### 3. Dependency Injection Registration

**File**: `lib/core/di/injection.dart` (or appropriate DI module)
**Changes**: Register cubit (if using @injectable, run code generation after)

The `@injectable` annotation should handle this automatically. After creating the cubit, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. BLoC Provider Configuration

**File**: `lib/core/providers/bloc_providers.dart`
**Changes**: Add PreviewComposerCubit to dashboard providers

```dart
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/core/di/injection.dart';

// Locate the blocProvidersDashboard() method and add:
static Widget blocProvidersDashboard() {
  return MultiBlocProvider(
    providers: [
      // Existing providers...
      BlocProvider<MessageSelectionCubit>(
        create: (_) => getIt<MessageSelectionCubit>(),
      ),

      // NEW: Preview composer cubit
      BlocProvider<PreviewComposerCubit>(
        create: (_) => getIt<PreviewComposerCubit>(),
      ),
    ],
    child: const DashboardScreen(),
  );
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No lint errors: `flutter analyze`
- [ ] Cubit registers with GetIt (verify app runs without DI errors)

#### Manual Verification:
- [ ] Cubit initializes with empty state
- [ ] `initialize()` sets title/description/coverImageUrl correctly
- [ ] `updateTitle()` validates required and max length
- [ ] `updateDescription()` validates required and max length
- [ ] `updateCoverImageUrl()` validates URL format
- [ ] `validate()` returns false when fields invalid
- [ ] `mockPublish()` sets `isPublishing` to true, waits 1 second, generates mock URL
- [ ] `reset()` clears all state

**Implementation Note**: After completing Phase 1 and all automated verification passes, manually test the cubit methods in isolation (via Flutter DevTools or debug prints) before proceeding to Phase 2.

---

## Phase 2: UI Widgets

### Overview
Build reusable UI components for the preview feature: selection counter, metadata form, and share panel.

### Changes Required:

#### 1. Message Selection Counter Widget

**File**: `lib/features/preview/presentation/widgets/message_selection_counter.dart`
**Changes**: Create new widget to display selection count

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Displays message selection count with validation indicator
class MessageSelectionCounter extends StatelessWidget {
  const MessageSelectionCounter({
    required this.selectedCount,
    required this.minCount,
    required this.maxCount,
    super.key,
  });

  final int selectedCount;
  final int minCount;
  final int maxCount;

  bool get isValid => selectedCount >= minCount && selectedCount <= maxCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isValid ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.info,
            size: 16,
            color: isValid ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            '$selectedCount / $maxCount selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isValid ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 2. Preview Metadata Form Widget

**File**: `lib/features/preview/presentation/widgets/preview_metadata_form.dart`
**Changes**: Create form for title/description/coverImageUrl input

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form for entering preview metadata
class PreviewMetadataForm extends StatefulWidget {
  const PreviewMetadataForm({super.key});

  @override
  State<PreviewMetadataForm> createState() => _PreviewMetadataFormState();
}

class _PreviewMetadataFormState extends State<PreviewMetadataForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverImageUrlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _coverImageUrlController = TextEditingController();

    // Initialize with state values
    final state = context.read<PreviewComposerCubit>().state;
    _titleController.text = state.title;
    _descriptionController.text = state.description;
    _coverImageUrlController.text = state.coverImageUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerCubit, PreviewComposerState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Preview Title *',
                hintText: 'Enter a catchy title for your preview',
                errorText: state.titleError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLength: 100,
              onChanged: (value) {
                context.read<PreviewComposerCubit>().updateTitle(value);
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Short Description *',
                hintText:
                    'Brief description to entice listeners (max 200 characters)',
                errorText: state.descriptionError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLines: 3,
              maxLength: PreviewComposerCubit.maxDescriptionLength,
              onChanged: (value) {
                context.read<PreviewComposerCubit>().updateDescription(value);
              },
            ),
            const SizedBox(height: 16),

            // Cover image URL field
            TextField(
              controller: _coverImageUrlController,
              decoration: InputDecoration(
                labelText: 'Cover Image URL (optional)',
                hintText: 'https://example.com/image.jpg',
                errorText: state.coverImageUrlError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                helperText: 'Leave empty to use conversation cover image',
              ),
              onChanged: (value) {
                context
                    .read<PreviewComposerCubit>()
                    .updateCoverImageUrl(value);
              },
            ),
          ],
        );
      },
    );
  }
}
```

#### 3. Preview Share Panel Widget

**File**: `lib/features/preview/presentation/widgets/preview_share_panel.dart`
**Changes**: Create widget for URL display and sharing

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Panel for displaying and sharing preview URL (demo version)
class PreviewSharePanel extends StatelessWidget {
  const PreviewSharePanel({
    required this.publicUrl,
    super.key,
  });

  final String publicUrl;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: publicUrl));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview URL copied to clipboard!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your preview is live! (Demo)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'In production, this URL would lead to a shareable preview page:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),

          // URL display box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              publicUrl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // Copy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy URL'),
              onPressed: () => _copyToClipboard(context),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Success Criteria:

#### Automated Verification:
- [ ] All widgets compile without errors: `flutter analyze`
- [ ] No lint errors: `flutter analyze`
- [ ] Widget tests pass (if written): `flutter test`

#### Manual Verification:
- [ ] MessageSelectionCounter displays correctly with different counts
- [ ] Counter shows green checkmark when count is 3-5
- [ ] Counter shows orange warning when count is <3 or >5
- [ ] PreviewMetadataForm renders all three input fields
- [ ] Form fields show error text when validation fails
- [ ] Character counters display correctly (100 for title, 200 for description)
- [ ] PreviewSharePanel displays URL in monospace font
- [ ] Copy button copies URL to clipboard and shows snackbar

**Implementation Note**: After Phase 2, test each widget in isolation using Flutter's widget testing or by temporarily adding them to an existing screen. Verify all visual states before proceeding to Phase 3.

---

## Phase 3: Screens and Navigation

### Overview
Create the preview composer and confirmation screens, integrate them into the routing system, and add the dashboard button.

### Changes Required:

#### 1. Route Definitions

**File**: `lib/core/routing/app_routes.dart`
**Changes**: Add preview route constants

```dart
class AppRoutes {
  AppRoutes._();

  // Existing routes...
  static const String settings = '/dashboard/settings';

  // NEW: Preview routes
  static const String previewComposer = '/dashboard/preview/composer';
  static const String previewConfirmation = '/dashboard/preview/confirmation';
}
```

#### 2. Preview Composer Screen

**File**: `lib/features/preview/presentation/screens/preview_composer_screen.dart`
**Changes**: Create full screen for composing preview

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_state.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/message_selection_counter.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_metadata_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Screen for composing a conversation preview (UI demo version)
class PreviewComposerScreen extends StatefulWidget {
  const PreviewComposerScreen({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  State<PreviewComposerScreen> createState() => _PreviewComposerScreenState();
}

class _PreviewComposerScreenState extends State<PreviewComposerScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize composer with conversation data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conversationState = context.read<ConversationBloc>().state;

      if (conversationState is ConversationLoaded) {
        final conversation = conversationState.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => conversationState.conversations.first,
        );

        context.read<PreviewComposerCubit>().initialize(
              conversationTitle: conversation.name,
              conversationDescription: conversation.description,
              conversationImageUrl: conversation.imageUrl,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreviewComposerCubit, PreviewComposerState>(
      listener: (context, state) {
        // Listen for mock publish completion
        if (state.mockPreviewUrl != null && !state.isPublishing) {
          // Navigate to confirmation screen
          context.go(
            '${AppRoutes.previewConfirmation}?url=${Uri.encodeComponent(state.mockPreviewUrl!)}',
          );

          // Reset state
          context.read<PreviewComposerCubit>().reset();
          context.read<MessageSelectionCubit>().clearSelection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Preview (Demo)'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<MessageSelectionCubit, MessageSelectionState>(
            builder: (context, selectionState) {
              final selectedCount = selectionState.selectedCount;
              final isValidSelection = selectedCount >= 3 && selectedCount <= 5;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'UI Demo Mode: No backend integration. Mock data only.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selection counter
                    MessageSelectionCounter(
                      selectedCount: selectedCount,
                      minCount: 3,
                      maxCount: 5,
                    ),

                    if (!isValidSelection) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Please select between 3 and 5 messages to include in your preview.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Form title
                    Text(
                      'Preview Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Metadata form
                    const PreviewMetadataForm(),
                    const SizedBox(height: 32),

                    // Publish button
                    BlocBuilder<PreviewComposerCubit, PreviewComposerState>(
                      builder: (context, composerState) {
                        final isPublishing = composerState.isPublishing;
                        final canPublish = isValidSelection &&
                            composerState.isValid &&
                            !isPublishing;

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: isPublishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.publish),
                            label: Text(
                              isPublishing
                                  ? 'Publishing...'
                                  : 'Publish Preview (Mock)',
                            ),
                            onPressed:
                                canPublish ? () => _handlePublish(context) : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handlePublish(BuildContext context) {
    // Validate form
    final isValid = context.read<PreviewComposerCubit>().validate();
    if (!isValid) return;

    // Get state
    final selectedMessageIds =
        context.read<MessageSelectionCubit>().getSelectedMessageIds();

    // Trigger mock publish
    context.read<PreviewComposerCubit>().mockPublish(
          conversationId: widget.conversationId,
          messageIds: selectedMessageIds.toList(),
        );
  }
}
```

#### 3. Preview Confirmation Screen

**File**: `lib/features/preview/presentation/screens/preview_confirmation_screen.dart`
**Changes**: Create success screen with sharing options

```dart
import 'package:carbon_voice_console/core/routing/app_routes.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/widgets/preview_share_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Screen showing successful preview publication (demo version)
class PreviewConfirmationScreen extends StatelessWidget {
  const PreviewConfirmationScreen({
    required this.mockPreviewUrl,
    super.key,
  });

  final String mockPreviewUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Published (Demo)'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success message
              Center(
                child: Text(
                  'Preview Published Successfully!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This is a UI demo. In production, your conversation preview would be live and ready to share.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Share panel
              PreviewSharePanel(publicUrl: mockPreviewUrl),
              const SizedBox(height: 32),

              // Back to dashboard button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Dashboard'),
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 4. Router Configuration

**File**: `lib/core/routing/app_router.dart`
**Changes**: Register preview routes in ShellRoute

```dart
import 'package:carbon_voice_console/features/preview/presentation/screens/preview_composer_screen.dart';
import 'package:carbon_voice_console/features/preview/presentation/screens/preview_confirmation_screen.dart';

// Locate the ShellRoute and add these new routes:
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    // Existing routes...
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SettingsScreen(),
      ),
    ),

    // NEW: Preview Composer route
    GoRoute(
      path: AppRoutes.previewComposer,
      name: 'previewComposer',
      pageBuilder: (context, state) {
        final conversationId = state.uri.queryParameters['conversationId'];

        return NoTransitionPage(
          child: PreviewComposerScreen(
            conversationId: conversationId ?? '',
          ),
        );
      },
    ),

    // NEW: Preview Confirmation route
    GoRoute(
      path: AppRoutes.previewConfirmation,
      name: 'previewConfirmation',
      pageBuilder: (context, state) {
        final mockPreviewUrl = state.uri.queryParameters['url'];

        return NoTransitionPage(
          child: PreviewConfirmationScreen(
            mockPreviewUrl: mockPreviewUrl ?? '',
          ),
        );
      },
    ),
  ],
)
```

#### 5. Dashboard Integration - Publish Button

**File**: Location depends on dashboard action panel implementation
**Changes**: Add "Publish Preview (Demo)" button to dashboard

**Note**: Based on your codebase structure, find the widget that renders action buttons for selected messages (likely in `lib/features/messages/presentation_messages_dashboard/`). Add this button:

```dart
// Example integration (adjust to match your actual button component):
ElevatedButton.icon(
  icon: const Icon(Icons.publish),
  label: const Text('Publish Preview (Demo)'),
  onPressed: () {
    final selectionCubit = context.read<MessageSelectionCubit>();
    final selectedCount = selectionCubit.state.selectedCount;

    // Validate selection
    if (selectedCount < 3 || selectedCount > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select between 3 and 5 messages for preview'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Get conversation ID
    final conversationState = context.read<ConversationBloc>().state;
    if (conversationState is ConversationLoaded &&
        conversationState.selectedConversationIds.isNotEmpty) {
      final conversationId = conversationState.selectedConversationIds.first;
      context.go('${AppRoutes.previewComposer}?conversationId=$conversationId');
    }
  },
)
```

### Success Criteria:

#### Automated Verification:
- [ ] All files compile without errors: `flutter analyze`
- [ ] No routing errors when navigating: `flutter run`
- [ ] No lint errors: `flutter analyze`

#### Manual Verification:
- [ ] "Publish Preview (Demo)" button appears in dashboard
- [ ] Button is disabled when <3 or >5 messages selected
- [ ] Clicking button with invalid selection shows snackbar error
- [ ] Clicking button with valid selection navigates to composer screen
- [ ] Composer screen displays demo banner at top
- [ ] Composer pre-fills title/description/image from conversation
- [ ] Form validation works in real-time
- [ ] Selection counter updates correctly
- [ ] "Publish Preview (Mock)" button disabled when form invalid
- [ ] Clicking publish shows loading state for ~1 second
- [ ] Success navigates to confirmation screen
- [ ] Confirmation screen shows success icon and mock URL
- [ ] Copy button copies URL to clipboard and shows snackbar
- [ ] Back button returns to dashboard
- [ ] Message selection is cleared after publish

**Implementation Note**: After Phase 3, perform full end-to-end manual testing of the entire flow. Verify each step from message selection to confirmation screen. Test all edge cases (invalid selection, form errors, etc.).

---

## Testing Strategy

### Widget Tests

Create basic widget tests for UI components:

**File**: `test/features/preview/presentation/widgets/message_selection_counter_test.dart`
- Test counter displays correctly with different counts
- Test color changes based on valid/invalid state
- Test icon changes based on valid/invalid state

**File**: `test/features/preview/presentation/widgets/preview_metadata_form_test.dart`
- Test form renders all fields
- Test error text displays when validation fails
- Test character counters display correctly

**File**: `test/features/preview/presentation/widgets/preview_share_panel_test.dart`
- Test URL displays correctly
- Test copy button interaction (mock clipboard)

### Manual Testing Steps

#### Happy Path:
1. [ ] Open dashboard, select exactly 3 messages
2. [ ] Click "Publish Preview (Demo)" button
3. [ ] Verify composer screen opens with pre-filled data
4. [ ] Edit title to "Test Preview"
5. [ ] Edit description to "This is a test preview description"
6. [ ] Leave cover image URL empty
7. [ ] Click "Publish Preview (Mock)"
8. [ ] Wait for 1-second mock delay
9. [ ] Verify navigation to confirmation screen
10. [ ] Verify mock URL displays
11. [ ] Click "Copy URL"
12. [ ] Verify snackbar shows "URL copied to clipboard"
13. [ ] Click "Back to Dashboard"
14. [ ] Verify message selection is cleared

#### Validation Errors:
1. [ ] Select 2 messages → click publish → verify snackbar error
2. [ ] Select 6 messages → click publish → verify snackbar error
3. [ ] In composer, clear title → verify error text appears
4. [ ] In composer, clear description → verify error text appears
5. [ ] In composer, enter invalid URL → verify error text appears
6. [ ] Enter title >100 chars → verify error text appears
7. [ ] Enter description >200 chars → verify error text appears

#### Edge Cases:
1. [ ] Test with conversation that has no description (should work)
2. [ ] Test with conversation that has no cover image (should work)
3. [ ] Test back button during mock publish (should cancel gracefully)
4. [ ] Test rapid button clicks (should prevent duplicate publishes)

## Migration to Full Implementation

When backend architecture is decided, follow these steps:

### Step 1: Implement Domain & Data Layers
Execute **Phase 1** from [`2025-12-09-public-conversation-previews.md`](2025-12-09-public-conversation-previews.md):
- Create domain entities (PreviewMetadata, ConversationPreview)
- Define repository interface
- Implement use cases
- Create DTOs and datasources
- Implement repository with API integration

### Step 2: Swap State Management
Replace `PreviewComposerCubit` with `PublishPreviewBloc` from the full plan:
- Update composer screen to listen to BLoC states
- Replace `mockPublish()` with real `PublishPreview` event
- Handle loading, success, and error states from BLoC

### Step 3: Update Confirmation Screen
Replace mock URL with real preview data:
- Use `GetPreviewUsecase` to fetch real preview
- Display actual public URL from backend
- Add error handling for failed fetches

### Step 4: Remove Demo Indicators
- Remove "UI Demo Mode" banner from composer screen
- Update confirmation screen text (remove "This is a UI demo")
- Update button labels (remove "(Demo)" and "(Mock)" text)

### Step 5: Add Tests
- Write unit tests for domain entities, use cases, repositories
- Write BLoC tests for state transitions
- Write integration tests for full publish flow

### Estimated Migration Time:
- Domain/Data layers: 2-4 hours
- BLoC integration: 1-2 hours
- Testing: 2-3 hours
- Total: ~6-9 hours (depending on backend complexity)

## Performance Considerations

### Current Implementation:
- **Local State Only**: No API calls, no caching needed
- **Minimal Rendering**: Form validation only updates on input change
- **Fast Navigation**: No async operations except 1-second mock delay

### Future Implementation:
- **In-Memory Cache**: Repository will cache previews by conversation ID
- **Debounced Validation**: Form validation should remain local
- **API Latency**: Real publish may take 2-5 seconds (add loading state)

## References

- **Full Implementation Plan**: [`2025-12-09-public-conversation-previews.md`](2025-12-09-public-conversation-previews.md)
- **Message Selection Pattern**: [message_selection_cubit.dart](lib/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart)
- **Routing Pattern**: [app_router.dart](lib/core/routing/app_router.dart)
- **Clean Architecture Guide**: [CLAUDE.md](CLAUDE.md)

---

## Summary

This plan delivers a **functional UI demonstration** of the public conversation preview feature without backend integration. It allows stakeholders to experience the complete user flow and provide feedback before committing to full backend development.

**What works:**
- ✅ Complete user journey (selection → composer → confirmation)
- ✅ Real-time form validation
- ✅ Message selection validation (3-5 messages)
- ✅ Mock publish with loading state
- ✅ URL copy to clipboard
- ✅ Clean, production-ready UI

**What's missing (intentionally):**
- ❌ No backend API integration
- ❌ No real preview generation
- ❌ No data persistence
- ❌ No domain/data layers

**Next steps:**
Once backend architecture is decided, execute the full implementation plan ([`2025-12-09-public-conversation-previews.md`](2025-12-09-public-conversation-previews.md)) to add domain/data layers and integrate with the real API. The UI code will require minimal changes during migration.
