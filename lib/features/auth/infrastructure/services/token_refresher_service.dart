import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/load_saved_token_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';

/// Proactive token refresh service
/// Refreshes token 60s before expiry if app is active
@LazySingleton()
class TokenRefresherService {
  final LoadSavedTokenUseCase _loadToken;
  final RefreshTokenUseCase _refreshToken;

  Timer? _refreshTimer;
  bool _isActive = true;

  TokenRefresherService(
    this._loadToken,
    this._refreshToken,
  );

  /// Start monitoring token expiry
  Future<void> startMonitoring() async {
    await _scheduleNextRefresh();
  }

  /// Stop monitoring (e.g., on logout or app background)
  void stopMonitoring() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _isActive = false;
  }

  /// Resume monitoring (e.g., app comes to foreground)
  Future<void> resume() async {
    _isActive = true;
    await _scheduleNextRefresh();
  }

  /// Pause monitoring (e.g., app goes to background)
  void pause() {
    _isActive = false;
    _refreshTimer?.cancel();
  }

  Future<void> _scheduleNextRefresh() async {
    _refreshTimer?.cancel();

    if (!_isActive) return;

    final tokenResult = await _loadToken();

    tokenResult.fold(
      onSuccess: (token) {
        if (token == null || !token.canRefresh) {
          return;
        }

        // Calculate time until refresh needed (60s buffer)
        final now = DateTime.now();
        final expiryWithBuffer = token.expiresAt.subtract(
          const Duration(seconds: 60),
        );
        final timeUntilRefresh = expiryWithBuffer.difference(now);

        if (timeUntilRefresh.isNegative) {
          // Token already needs refresh
          _performRefresh();
        } else {
          // Schedule refresh
          _refreshTimer = Timer(timeUntilRefresh, _performRefresh);
        }
      },
      onFailure: (_) {
        // No token or error - stop monitoring
        stopMonitoring();
      },
    );
  }

  Future<void> _performRefresh() async {
    if (!_isActive) return;

    final result = await _refreshToken();

    result.fold(
      onSuccess: (_) {
        // Schedule next refresh
        _scheduleNextRefresh();
      },
      onFailure: (_) {
        // Refresh failed - stop monitoring
        stopMonitoring();
      },
    );
  }

  void dispose() {
    stopMonitoring();
  }
}
