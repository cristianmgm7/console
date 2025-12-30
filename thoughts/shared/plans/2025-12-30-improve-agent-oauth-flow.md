# Improve Agent OAuth Authentication Flow - Implementation Plan

## Overview

Currently, when the agent requires OAuth authentication (e.g., for MCP tools like GitHub), users must manually:
1. Copy the OAuth URL from the dialog
2. Open it in their browser
3. Complete authentication
4. Copy the authorization code
5. Paste it back into the dialog

This plan implements an **automated, user-friendly OAuth flow** where:
1. Users click a button to open the OAuth URL
2. The app automatically captures the authorization code via deep link
3. The code is automatically sent to the agent
4. The dialog closes and authentication completes seamlessly

## Current State Analysis

### Existing Infrastructure

**OAuth Callback System (for Carbon Voice login):**
- Deep link scheme: `carbonvoice://` configured in `macos/Runner/Info.plist`
- Callback route: `/auth/callback` in `app_router.dart`
- Callback screen: `oauth_callback_screen.dart` handles deep link redirects
- Web redirect page: `web_redirect_page.html` handles browser → app transition

**Agent Authentication Dialog:**
- File: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
- Currently shows URL in a text box with copy button
- Requires manual code input via text field
- Sends code via `AuthCodeProvided` event to `McpAuthBloc`

**MCP Auth Bloc:**
- File: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
- Handles `AuthCodeProvided` event
- Exchanges code for OAuth2 credentials using `oauth2` package
- Sends credentials to agent via `SendAuthenticationCredentialsUseCase`

### Key Discoveries

1. **Deep link infrastructure exists** but only configured for macOS (`carbonvoice://`)
2. **url_launcher package** is already in `pubspec.yaml` (v6.3.2)
3. **OAuth callback screen** already handles deep link callbacks for user login
4. **Agent OAuth uses different redirect URI** than user login (GitHub OAuth, etc.)
5. **State management** via `McpAuthBloc` is well-structured for async flows

### Current Limitations

1. No deep link handling for **agent OAuth callbacks** (only user login)
2. Manual code copy/paste creates friction
3. No visual feedback during OAuth flow
4. Dialog doesn't support opening URLs directly
5. Android deep link configuration missing

## What We're NOT Doing

- ❌ Changing the backend agent OAuth flow
- ❌ Modifying the ADK authentication protocol
- ❌ Implementing OAuth for iOS (focus on macOS/web first)
- ❌ Changing the existing user login OAuth flow
- ❌ Supporting multiple simultaneous OAuth flows

## Implementation Approach

We'll create a **parallel OAuth callback route** specifically for agent authentication that:
1. Uses the same deep link scheme (`carbonvoice://`)
2. Has a different path (`/agent-auth/callback`)
3. Communicates with `McpAuthBloc` instead of `AuthBloc`
4. Automatically closes the dialog when complete

The flow will be:
1. User clicks "Authenticate" button in dialog
2. App opens OAuth URL in system browser via `url_launcher`
3. User completes OAuth in browser
4. Browser redirects to `carbonvoice://agent-auth/callback?code=XXX&state=YYY`
5. App captures deep link, extracts code
6. App sends code to `McpAuthBloc` automatically
7. Dialog shows "Authenticating..." state
8. Dialog closes on success/error

---

## Phase 1: Add Agent OAuth Callback Route

### Overview
Create a new route and screen to handle OAuth callbacks specifically for agent authentication, separate from user login.

### Changes Required

#### 1. Create Agent OAuth Callback Screen
**File**: `lib/features/agent_chat/presentation/pages/agent_oauth_callback_screen.dart`

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart';
import 'package:carbon_voice_console/features/agent_chat/presentation/bloc/mcp_auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen that handles OAuth callbacks for agent authentication (MCP tools).
/// 
/// This is separate from the user login OAuth callback and specifically
/// handles authentication for MCP tools like GitHub, Atlassian, etc.
/// 
/// Flow:
/// 1. User completes OAuth in browser
/// 2. Browser redirects to carbonvoice://agent-auth/callback?code=XXX&state=YYY
/// 3. This screen extracts the code and state
/// 4. Sends AuthCodeProvidedFromDeepLink event to McpAuthBloc
/// 5. Shows loading state while authentication completes
/// 6. Auto-closes when done
class AgentOAuthCallbackScreen extends StatefulWidget {
  const AgentOAuthCallbackScreen({
    required this.callbackUri,
    super.key,
  });

  final Uri callbackUri;

  @override
  State<AgentOAuthCallbackScreen> createState() => _AgentOAuthCallbackScreenState();
}

class _AgentOAuthCallbackScreenState extends State<AgentOAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  void _handleCallback() {
    final code = widget.callbackUri.queryParameters['code'];
    final state = widget.callbackUri.queryParameters['state'];
    final error = widget.callbackUri.queryParameters['error'];
    final errorDescription = widget.callbackUri.queryParameters['error_description'];

    if (error != null) {
      // OAuth error - show error and close after delay
      _showErrorAndClose(error, errorDescription);
      return;
    }

    if (code == null || state == null) {
      _showErrorAndClose('invalid_callback', 'Missing authorization code or state');
      return;
    }

    // Success - send code to McpAuthBloc
    // The bloc will handle the code exchange and credential sending
    context.read<McpAuthBloc>().add(
      AuthCodeProvidedFromDeepLink(
        authorizationCode: code,
        state: state,
      ),
    );
  }

  void _showErrorAndClose(String error, String? description) {
    // Show error snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: $error${description != null ? ' - $description' : ''}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Close this screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientPurple,
              AppColors.gradientPink,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Completing authentication...',
                style: AppTextStyle.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This window will close automatically',
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
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

#### 2. Add Route to App Router
**File**: `lib/core/routing/app_router.dart`
**Changes**: Add new route after the existing OAuth callback route

```dart
// After line 60, add new agent OAuth callback route:

// Agent OAuth callback route (for MCP tool authentication)
GoRoute(
  path: AppRoutes.agentOAuthCallback,
  name: 'agentOAuthCallback',
  pageBuilder: (context, state) {
    final fullUri = state.uri;
    return MaterialPage(
      key: state.pageKey,
      child: AgentOAuthCallbackScreen(
        callbackUri: fullUri,
      ),
    );
  },
),
```

#### 3. Add Route Constant
**File**: `lib/core/routing/app_routes.dart`
**Changes**: Add new route constant

```dart
// Add after oauthCallback constant:
static const String agentOAuthCallback = '/agent-auth/callback';
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] No linting errors: `flutter analyze`
- [ ] Route is registered in router: Check `app_router.dart`

#### Manual Verification:
- [ ] Navigate to `carbonvoice://agent-auth/callback?code=test123&state=abc` shows callback screen
- [ ] Screen displays loading indicator
- [ ] Screen shows "Completing authentication..." message
- [ ] Invalid callback (missing code) shows error and closes after 3 seconds

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the route navigation works before proceeding to Phase 2.

---

## Phase 2: Update MCP Auth Bloc to Handle Deep Link Callbacks

### Overview
Add new event and handler to `McpAuthBloc` to process authorization codes from deep links, including state validation.

### Changes Required

#### 1. Add New Event
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_event.dart`
**Changes**: Add new event class

```dart
// Add after AuthCodeProvided class:

/// Event fired when an authorization code is provided via deep link callback.
/// 
/// This is different from AuthCodeProvided which is for manual code entry.
/// This event includes the state parameter for validation and needs to
/// match it with the pending auth request.
class AuthCodeProvidedFromDeepLink extends McpAuthEvent {
  const AuthCodeProvidedFromDeepLink({
    required this.authorizationCode,
    required this.state,
  });

  final String authorizationCode;
  final String state;

  @override
  List<Object?> get props => [authorizationCode, state];
}
```

#### 2. Add State Tracking to Bloc
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
**Changes**: Add state tracking for pending auth requests

```dart
// Add after line 27 (after final Logger _logger;):

// Track pending auth requests by state parameter
final Map<String, PendingAuthRequest> _pendingAuthRequests = {};

/// Store a pending auth request when dialog is shown
void _storePendingAuthRequest(String state, AuthenticationRequest request, String sessionId) {
  _pendingAuthRequests[state] = PendingAuthRequest(
    request: request,
    sessionId: sessionId,
    timestamp: DateTime.now(),
  );
}

/// Retrieve and remove a pending auth request by state
PendingAuthRequest? _consumePendingAuthRequest(String state) {
  return _pendingAuthRequests.remove(state);
}

/// Clear old pending requests (older than 10 minutes)
void _clearOldPendingRequests() {
  final now = DateTime.now();
  _pendingAuthRequests.removeWhere((key, value) {
    return now.difference(value.timestamp).inMinutes > 10;
  });
}
```

#### 3. Update Auth Request Handler to Store State
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
**Changes**: Modify `_onAuthRequestDetected` to store pending requests

```dart
// In _onAuthRequestDetected method, after line 94 (after logging auth URL):

// Store pending auth request with state for deep link callback
_storePendingAuthRequest(
  request.state,
  request,
  event.sessionId,
);

// Clean up old pending requests
_clearOldPendingRequests();
```

#### 4. Register New Event Handler
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
**Changes**: Add handler registration in constructor

```dart
// In constructor, after line 22:
on<AuthCodeProvidedFromDeepLink>(_onAuthCodeProvidedFromDeepLink);
```

#### 5. Implement Deep Link Handler
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
**Changes**: Add new handler method after `_onAuthCodeProvided`

```dart
/// Handle auth code provided via deep link callback
Future<void> _onAuthCodeProvidedFromDeepLink(
  AuthCodeProvidedFromDeepLink event,
  Emitter<McpAuthState> emit,
) async {
  _logger.i('🔐 Received auth code from deep link with state: ${event.state}');

  // Retrieve the pending auth request
  final pendingRequest = _consumePendingAuthRequest(event.state);
  
  if (pendingRequest == null) {
    _logger.e('🔐 No pending auth request found for state: ${event.state}');
    emit(McpAuthError(
      message: 'Invalid authentication state. Please try again.',
      sessionId: '', // We don't have session ID without pending request
    ));
    return;
  }

  _logger.i('🔐 Found pending auth request for provider: ${pendingRequest.request.provider}');

  // Process the auth code using the same logic as manual code entry
  final provider = pendingRequest.request.provider ?? 'oauth2';
  
  emit(McpAuthProcessing(
    provider: provider,
    sessionId: pendingRequest.sessionId,
  ));

  try {
    // Exchange authorization code for credentials
    final credentials = await _completeOAuth2Flow(
      authorizationCode: event.authorizationCode,
      request: pendingRequest.request,
    );

    if (credentials == null) {
      throw Exception('Failed to obtain credentials from OAuth provider');
    }

    // Send credentials back to agent
    final sendResult = await _sendCredentialsUseCase(
      sessionId: pendingRequest.sessionId,
      provider: provider,
      credentials: credentials,
    );

    sendResult.fold(
      onSuccess: (_) {
        emit(McpAuthSuccess(
          provider: provider,
          sessionId: pendingRequest.sessionId,
        ));
      },
      onFailure: (failure) {
        _logger.e('Failed to send authentication credentials', error: failure);
        emit(McpAuthError(
          message: 'Failed to send credentials: ${failure.failure.details ?? failure.failure.code}',
          sessionId: pendingRequest.sessionId,
        ));
      },
    );

    // Return to listening state
    emit(McpAuthListening(sessionId: pendingRequest.sessionId));
  } catch (e, stackTrace) {
    _logger.e('Authentication failed', error: e, stackTrace: stackTrace);

    // Send error to agent
    final errorResult = await _sendCredentialsUseCase.sendError(
      sessionId: pendingRequest.sessionId,
      provider: provider,
      errorMessage: e.toString(),
    );

    errorResult.fold(
      onSuccess: (_) {
        _logger.i('Authentication error sent to agent successfully');
      },
      onFailure: (failure) {
        _logger.e('Failed to send authentication error to agent', error: failure);
      },
    );

    emit(McpAuthError(
      message: e.toString(),
      sessionId: pendingRequest.sessionId,
    ));
  }
}
```

#### 6. Add Pending Request Data Class
**File**: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
**Changes**: Add at the bottom of the file (after the class)

```dart
/// Represents a pending authentication request waiting for callback
class PendingAuthRequest {
  const PendingAuthRequest({
    required this.request,
    required this.sessionId,
    required this.timestamp,
  });

  final AuthenticationRequest request;
  final String sessionId;
  final DateTime timestamp;
}
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] No linting errors: `flutter analyze`
- [ ] Event is properly registered in bloc constructor
- [ ] State tracking map is initialized

#### Manual Verification:
- [ ] Pending auth requests are stored when dialog appears
- [ ] Deep link callback finds matching pending request by state
- [ ] Old pending requests (>10 minutes) are cleaned up
- [ ] Invalid state parameter shows appropriate error
- [ ] Successful auth code exchange sends credentials to agent

**Implementation Note**: After completing this phase, test that the bloc can store and retrieve pending auth requests before proceeding to Phase 3.

---

## Phase 3: Update Authentication Dialog with Button and Auto-Close

### Overview
Replace the manual URL copy/paste flow with a button that opens the OAuth URL, and add logic to auto-close the dialog when authentication completes.

### Changes Required

#### 1. Update Dialog Widget
**File**: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
**Changes**: Replace manual flow with button-based flow

```dart
// Remove _authCodeController and related code (lines 28-36)
// Remove _handleAuthenticate method (lines 38-54)

// Update state class (replace lines 27-36):
class _McpAuthenticationDialogState extends State<McpAuthenticationDialog> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void dispose() {
    super.dispose();
  }

  // Add method to open OAuth URL
  Future<void> _openAuthUrl() async {
    final url = widget.request.authUri.isNotEmpty 
        ? widget.request.correctedAuthUri 
        : widget.request.authorizationUrl ?? '';
    
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'No authorization URL provided';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Open URL in system browser
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Failed to open browser. Please try again.';
        });
      }
      // Note: Keep _isAuthenticating = true
      // Dialog will auto-close when McpAuthBloc emits success/error
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Error opening browser: $e';
      });
    }
  }

  // Keep _copyUrlToClipboard method (lines 56-67) as fallback
```

#### 2. Update Dialog Content
**File**: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
**Changes**: Replace Step 1/Step 2 UI with button-based UI

```dart
// Replace the "Step 1" and "Step 2" sections (lines 133-189) with:

// Primary action button
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.primary),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Click the button below to authenticate',
        style: AppTextStyle.labelMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      AppButton(
        onPressed: _isAuthenticating ? null : _openAuthUrl,
        isLoading: _isAuthenticating,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isAuthenticating) ...[
              const Icon(Icons.open_in_browser, size: 20),
              const SizedBox(width: 8),
            ],
            Text(_isAuthenticating ? 'Waiting for authentication...' : 'Open Browser to Authenticate'),
          ],
        ),
      ),
      if (_isAuthenticating) ...[
        const SizedBox(height: 12),
        Text(
          'Complete the authentication in your browser.\nThis dialog will close automatically when done.',
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  ),
),

const SizedBox(height: 16),

// Fallback: Manual URL copy (collapsed by default)
ExpansionTile(
  title: Text(
    'Advanced: Manual authentication',
    style: AppTextStyle.labelSmall.copyWith(
      color: AppColors.textSecondary,
    ),
  ),
  children: [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Authorization URL',
                  style: AppTextStyle.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: _copyUrlToClipboard,
                tooltip: 'Copy URL',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.request.authUri.isNotEmpty 
                ? widget.request.correctedAuthUri 
                : widget.request.authorizationUrl ?? 'No URL provided',
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    ),
  ],
),

if (_errorMessage != null) ...[
  const SizedBox(height: 12),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.error),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMessage!,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    ),
  ),
],
```

#### 3. Add Import for url_launcher
**File**: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
**Changes**: Add import at top of file

```dart
import 'package:url_launcher/url_launcher.dart';
```

#### 4. Add Auto-Close Logic to Dialog Listener
**File**: `lib/features/agent_chat/presentation/widgets/mcp_auth_listener.dart`
**Changes**: Update to close dialog on success/error

```dart
// Update _showAuthenticationDialog method (lines 43-72):

void _showAuthenticationDialog(BuildContext context, McpAuthRequired state) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BlocListener<McpAuthBloc, McpAuthState>(
      listener: (context, authState) {
        // Auto-close dialog on success or error
        if (authState is McpAuthSuccess || authState is McpAuthError) {
          Navigator.of(dialogContext).pop();
          
          // Show feedback snackbar
          if (authState is McpAuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully authenticated with ${authState.provider}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (authState is McpAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication failed: ${authState.message}'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: McpAuthenticationDialog(
        request: state.request,
        onAuthenticate: (authCode) {
          // This is now only used for manual code entry (fallback)
          context.read<McpAuthBloc>().add(
                AuthCodeProvided(
                  authorizationCode: authCode,
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
        },
        onCancel: () {
          context.read<McpAuthBloc>().add(
                AuthCancelled(
                  request: state.request,
                  sessionId: state.sessionId,
                ),
              );
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}
```

#### 5. Update Dialog Actions
**File**: `lib/features/agent_chat/presentation/widgets/mcp_authentication_dialog.dart`
**Changes**: Simplify action buttons (replace lines 203-214)

```dart
actions: [
  AppOutlinedButton(
    onPressed: _isAuthenticating ? null : widget.onCancel,
    isLoading: false,
    child: const Text('Cancel'),
  ),
],
```

### Success Criteria

#### Automated Verification:
- [ ] Code compiles without errors: `flutter analyze`
- [ ] No linting errors: `flutter analyze`
- [ ] url_launcher import is valid
- [ ] Dialog widget builds without errors

#### Manual Verification:
- [ ] "Open Browser to Authenticate" button appears in dialog
- [ ] Clicking button opens OAuth URL in system browser
- [ ] Button shows loading state after opening browser
- [ ] Dialog shows "Waiting for authentication..." message
- [ ] Dialog auto-closes on successful authentication
- [ ] Dialog auto-closes on authentication error
- [ ] Success snackbar appears after successful auth
- [ ] Error snackbar appears after failed auth
- [ ] Manual URL copy is available in collapsed "Advanced" section
- [ ] Cancel button works correctly

**Implementation Note**: After completing this phase, test the full flow: open dialog → click button → complete OAuth in browser → verify dialog closes automatically.

---

## Phase 4: Update Web Redirect Page for Agent OAuth

### Overview
Modify the web redirect page to support agent OAuth callbacks with a different deep link path.

### Changes Required

#### 1. Update Redirect Page to Support Agent OAuth
**File**: `web_redirect_page.html`
**Changes**: Add logic to detect and handle agent OAuth callbacks

```html
<!-- Replace the JavaScript section (lines 85-149) with: -->

<script>
    // Get URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const code = urlParams.get('code');
    const state = urlParams.get('state');
    const error = urlParams.get('error');
    const errorDescription = urlParams.get('error_description');
    const agentAuth = urlParams.get('agent_auth'); // Flag to indicate agent OAuth

    const statusEl = document.getElementById('status');
    const containerEl = document.getElementById('container');
    const manualActionEl = document.getElementById('manual-action');
    const manualLinkEl = document.getElementById('manual-link');
    const deepLinkEl = document.getElementById('deep-link');

    if (error) {
        // OAuth error
        containerEl.innerHTML = `
            <div class="error" style="font-size: 60px;">❌</div>
            <h1>Authentication Failed</h1>
            <p class="error"><strong>Error:</strong> ${error}</p>
            ${errorDescription ? `<p>${errorDescription}</p>` : ''}
            <p>Please close this window and try again.</p>
        `;
    } else if (!code) {
        // Missing code parameter
        containerEl.innerHTML = `
            <div class="error" style="font-size: 60px;">⚠️</div>
            <h1>Invalid Callback</h1>
            <p class="error">Missing authorization code.</p>
            <p>Please close this window and try logging in again.</p>
        `;
    } else {
        // Success - build deep link
        // Use different path for agent OAuth vs user login
        const basePath = agentAuth === 'true' ? 'agent-auth/callback' : 'auth/callback';
        let deepLink = `carbonvoice://${basePath}?code=${encodeURIComponent(code)}`;
        if (state) {
            deepLink += `&state=${encodeURIComponent(state)}`;
        }

        // Set manual link
        manualLinkEl.href = deepLink;
        deepLinkEl.textContent = deepLink;

        // Update title based on auth type
        if (agentAuth === 'true') {
            containerEl.querySelector('h1').textContent = 'Completing Agent Authentication...';
        }

        // Try to automatically open the app
        statusEl.textContent = 'Opening Carbon Voice Console...';

        // Attempt to redirect
        window.location.href = deepLink;

        // Show manual action after 3 seconds if still on page
        setTimeout(() => {
            statusEl.textContent = 'If the app doesn\'t open automatically, use the button below:';
            manualActionEl.style.display = 'block';
            document.querySelector('.spinner').style.display = 'none';
        }, 3000);

        // Try to close window after redirect (may not work in all browsers)
        setTimeout(() => {
            try {
                window.close();
            } catch (e) {
                console.log('Could not auto-close window:', e);
            }
        }, 5000);
    }
</script>
```

### Success Criteria

#### Automated Verification:
- [ ] HTML file is valid (no syntax errors)
- [ ] JavaScript logic is correct

#### Manual Verification:
- [ ] User login callback uses `carbonvoice://auth/callback` path
- [ ] Agent OAuth callback uses `carbonvoice://agent-auth/callback` path
- [ ] Page detects `agent_auth=true` parameter correctly
- [ ] Page shows appropriate title for agent auth
- [ ] Deep link is constructed correctly for both flows
- [ ] Manual fallback link works for both flows

**Implementation Note**: To test agent OAuth, you'll need to modify the agent's redirect URI to include `?agent_auth=true` parameter. This will be done in Phase 5.

---

## Phase 5: Update Agent OAuth Configuration

### Overview
Configure the agent's OAuth redirect URI to use the web redirect page with the agent_auth flag.

### Changes Required

#### 1. Update Agent OAuth Redirect URI
**File**: `agent/agent/agent.py`
**Changes**: Update redirect_uri in OAuth2Auth configuration

```python
# Update lines 85-86:
redirect_uri=os.getenv(
    "CARBON_REDIRECT_URI", 
    "https://cristianmgm7.github.io/carbon-console-auth/?agent_auth=true"
),
```

### Success Criteria

#### Automated Verification:
- [ ] Python code has no syntax errors: `python -m py_compile agent/agent/agent.py`
- [ ] Agent starts without errors: `python agent/serve_openapi.py`

#### Manual Verification:
- [ ] Agent generates OAuth URLs with correct redirect_uri
- [ ] Redirect URI includes `?agent_auth=true` parameter
- [ ] OAuth flow redirects to web page correctly
- [ ] Web page redirects to agent OAuth callback route

**Implementation Note**: After this phase, test the complete end-to-end flow with a real OAuth provider (e.g., GitHub).

---

## Phase 6: Add Android Deep Link Support (Optional)

### Overview
Configure Android to handle the `carbonvoice://` deep link scheme for agent OAuth callbacks.

### Changes Required

#### 1. Update Android Manifest
**File**: `android/app/src/main/AndroidManifest.xml`
**Changes**: Add intent filter for deep links

```xml
<!-- Add inside the <activity> tag, after the existing intent-filter (after line 26): -->

<!-- Deep link intent filter for OAuth callbacks -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="carbonvoice"
        android:host="auth"/>
    <data
        android:scheme="carbonvoice"
        android:host="agent-auth"/>
</intent-filter>
```

### Success Criteria

#### Automated Verification:
- [ ] Android manifest is valid XML
- [ ] App builds for Android: `flutter build apk --debug`

#### Manual Verification:
- [ ] Deep links open the app on Android
- [ ] `carbonvoice://auth/callback` opens user login callback
- [ ] `carbonvoice://agent-auth/callback` opens agent OAuth callback
- [ ] OAuth flow works end-to-end on Android

**Implementation Note**: This phase is optional and can be done later if Android support is needed.

---

## Testing Strategy

### Unit Tests

**File**: `test/features/agent_chat/presentation/bloc/mcp_auth_bloc_test.dart`

Test cases to add:
1. `AuthCodeProvidedFromDeepLink` with valid state finds pending request
2. `AuthCodeProvidedFromDeepLink` with invalid state emits error
3. Pending requests are stored when auth request is detected
4. Old pending requests (>10 minutes) are cleaned up
5. Deep link auth code exchange succeeds and sends credentials
6. Deep link auth code exchange fails and sends error

### Integration Tests

**File**: `integration_test/agent_oauth_flow_test.dart`

Test scenarios:
1. Full OAuth flow: dialog → button click → browser opens → callback → dialog closes
2. OAuth error handling: invalid callback → error snackbar
3. State validation: mismatched state → error
4. Timeout handling: pending request expires after 10 minutes

### Manual Testing Steps

#### Test 1: Happy Path - Successful OAuth
1. Open agent chat
2. Send message that requires OAuth (e.g., "list my GitHub repositories")
3. Verify authentication dialog appears
4. Click "Open Browser to Authenticate" button
5. Verify browser opens with OAuth URL
6. Complete OAuth in browser
7. Verify app comes to foreground
8. Verify dialog closes automatically
9. Verify success snackbar appears
10. Verify agent receives credentials and completes request

#### Test 2: OAuth Error
1. Open agent chat
2. Trigger OAuth dialog
3. Click authenticate button
4. In browser, click "Cancel" or "Deny"
5. Verify app shows error snackbar
6. Verify dialog closes
7. Verify agent receives error notification

#### Test 3: Manual Fallback
1. Open agent chat
2. Trigger OAuth dialog
3. Expand "Advanced: Manual authentication" section
4. Copy URL manually
5. Complete OAuth in browser
6. Copy authorization code
7. Paste code in dialog (if we keep this fallback)
8. Verify authentication completes

#### Test 4: State Validation
1. Trigger OAuth dialog (stores state)
2. Wait 11 minutes (or manually clear pending requests)
3. Complete OAuth in browser
4. Verify error message about invalid state
5. Verify dialog closes with error

---

## Performance Considerations

1. **Pending Request Cleanup**: Automatically clean up requests older than 10 minutes to prevent memory leaks
2. **Browser Launch**: Use `LaunchMode.externalApplication` to ensure browser opens in separate app
3. **Dialog State**: Keep dialog open during OAuth to provide visual feedback
4. **Deep Link Handling**: Process deep links immediately in callback screen
5. **Error Recovery**: Clear pending requests on error to prevent stuck states

---

## Migration Notes

### For Existing Users
- No migration needed - this is a pure UX improvement
- Old manual flow is still available as fallback in "Advanced" section
- No changes to stored credentials or session data

### For Developers
- New route `/agent-auth/callback` must be registered
- `McpAuthBloc` now tracks pending auth requests
- Web redirect page supports both user login and agent OAuth
- Android manifest may need updating for deep link support

---

## References

- Original screenshot: User authentication dialog with manual URL/code entry
- Existing OAuth implementation: `lib/features/auth/data/repositories/oauth_repository_impl.dart`
- Deep link configuration: `macos/Runner/Info.plist`
- Web redirect page: `web_redirect_page.html`
- MCP Auth Bloc: `lib/features/agent_chat/presentation/bloc/mcp_auth_bloc.dart`
- url_launcher package: https://pub.dev/packages/url_launcher

