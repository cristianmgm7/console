# Refactor State Helpers

You are tasked with refactoring Flutter widget files that contain BlocBuilders to extract state-specific logic into helper methods, improving code readability, debuggability, and testability.

## Purpose

When working with BlocBuilders, it's common to have large conditional blocks inside the `builder` function that handle different states. This command helps extract these into well-named helper methods that clearly indicate what UI is shown for each state.

## Evaluation Criteria

When evaluating a widget file:

- **Extract State Helper Methods if:**
  - The widget contains BlocBuilder/BlocSelector with complex conditional logic
  - There are multiple if-else branches handling different states
  - The state handling logic is complex enough to deserve separation
  - It would improve readability and make unit testing easier

- **Keep Inline if:**
  - The state handling is very simple (1-2 lines)
  - There's only one state condition
  - The logic is trivial and doesn't benefit from extraction

## Refactor Rules

**CRITICAL: All functionality must remain exactly the same. The UI output, behavior, and performance characteristics must be identical before and after the refactor.**

When performing a refactor:

1. **Identify State Patterns**: Look for BlocBuilder patterns like:
   ```dart
   BlocBuilder<MyBloc, MyState>(
     builder: (context, state) {
       if (state is StateA) {
         return WidgetA();
       } else if (state is StateB) {
         return WidgetB();
       } else {
         return DefaultWidget();
       }
     },
   )
   ```

2. **Create Helper Methods**: Extract each state condition into a private method:
   ```dart
   Widget _buildStateA(MyState state) => WidgetA();
   Widget _buildStateB(MyState state) => WidgetB();
   Widget _buildDefaultState() => DefaultWidget();
   ```

3. **Refactor Main Builder**: Simplify the builder to use helper methods:
   ```dart
   BlocBuilder<MyBloc, MyState>(
     builder: (context, state) {
       if (state is StateA) {
         return _buildStateA(state);
       } else if (state is StateB) {
         return _buildStateB(state);
       } else {
         return _buildDefaultState();
       }
     },
   )
   ```

4. **Advanced Patterns**: For more complex cases, consider:
   ```dart
   Widget _buildStateFromUnion(MyState state) {
     return switch (state) {
       StateA() => _buildStateA(state),
       StateB() => _buildStateB(state),
       _ => _buildDefaultState(),
     };
   }
   ```

## File Handling Steps

When called with a file path:

1. Read the entire file to understand BlocBuilder patterns
2. Identify complex state handling logic in builders
3. Evaluate each BlocBuilder using the **Evaluation Criteria**
4. Extract state handlers into private helper methods
5. Update the BlocBuilder to use the helper methods
6. Save the updated file

If no widget files are provided, request one.

## Communication Protocol

When changes are complete, respond using this format:

```
State Helpers Refactor Complete

Changed:
- Refactored `MyWidget` BlocBuilder with 3 state conditions
- Created `_buildLoadingState()`, `_buildLoadedState(LoadedState)`, `_buildErrorState(ErrorState)`

Reasoning:
- Improved readability by separating state-specific UI logic
- Made each state handler independently testable
- Reduced complexity in main build method

Ready for review.
```

If unsure about a case:
```
State Helpers Decision Pending

Widget: `MyWidget`
BlocBuilder: `MyBloc`
Reason: Complex state logic with multiple conditions that could benefit from extraction
Requesting confirmation before proceeding.
```

## Examples

### Before:
```dart
BlocBuilder<MessageBloc, MessageState>(
  builder: (context, messageState) {
    if (isAnyBlocLoading(context)) {
      return const Center(child: AppProgressIndicator());
    }

    if (messageState is MessageError) {
      return AppEmptyState.error(
        message: messageState.message,
        onRetry: () => context.read<WorkspaceBloc>().add(const LoadWorkspaces()),
      );
    }

    if (messageState is MessageLoaded) {
      if (messageState.messages.isEmpty) {
        return AppEmptyState.noMessages(
          onRetry: () => context.read<WorkspaceBloc>().add(const LoadWorkspaces()),
        );
      }
      return _buildMessageTable(messageState, audioState);
    }

    return AppEmptyState.loading();
  },
)
```

### After:
```dart
BlocBuilder<MessageBloc, MessageState>(
  builder: (context, messageState) {
    if (isAnyBlocLoading(context)) {
      return _buildLoadingState();
    }

    if (messageState is MessageError) {
      return _buildErrorState(messageState);
    }

    if (messageState is MessageLoaded) {
      return _buildLoadedState(messageState, audioState);
    }

    return _buildInitialLoadingState();
  },
)

Widget _buildLoadingState() => const Center(child: AppProgressIndicator());

Widget _buildErrorState(MessageError errorState) {
  return AppEmptyState.error(
    message: errorState.message,
    onRetry: () => context.read<WorkspaceBloc>().add(const LoadWorkspaces()),
  );
}

Widget _buildLoadedState(MessageLoaded loadedState, AudioPlayerState audioState) {
  if (loadedState.messages.isEmpty) {
    return _buildEmptyMessagesState();
  }
  return _buildMessageTable(loadedState, audioState);
}

Widget _buildEmptyMessagesState() {
  return AppEmptyState.noMessages(
    onRetry: () => context.read<WorkspaceBloc>().add(const LoadWorkspaces()),
  );
}

Widget _buildInitialLoadingState() => AppEmptyState.loading();
```

This pattern makes the code much more readable and each state handler can be tested independently.
