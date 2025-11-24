import '../../../../core/utils/result.dart';
import '../entities/token.dart';
import '../entities/oauth_flow_state.dart';

/// Repository interface - contract for auth operations
abstract class AuthRepository {
  /// Generate OAuth authorization URL
  Future<Result<String>> generateAuthorizationUrl();

  /// Get current OAuth flow state (FIXED: Now async)
  Future<Result<OAuthFlowState?>> getCurrentFlowState();

  /// Exchange authorization code for access token
  Future<Result<Token>> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  });

  /// Refresh access token using refresh token
  Future<Result<Token>> refreshToken(String refreshToken);

  /// Save token to secure storage
  Future<Result<void>> saveToken(Token token);

  /// Load saved token from secure storage
  Future<Result<Token?>> loadSavedToken();

  /// Revoke token and clear storage
  Future<Result<void>> logout();

  /// Clear all auth data
  Future<Result<void>> clearAuthData();
}
