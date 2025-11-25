import 'package:oauth2/oauth2.dart' as oauth2;
import '../../../../core/utils/result.dart';

abstract class OAuthRepository {
  /// Inicia el flujo de autenticación y devuelve la URL de autorización
  Future<Result<String>> getAuthorizationUrl();

  /// Completa el flujo de autenticación con el código recibido
  Future<Result<oauth2.Client>> handleAuthorizationResponse(String responseUrl);

  /// Carga el cliente OAuth guardado (si existe y es válido)
  Future<Result<oauth2.Client?>> loadSavedClient();

  /// Verifica si hay una sesión activa
  Future<Result<bool>> isAuthenticated();

  /// Cierra sesión y elimina las credenciales
  Future<Result<void>> logout();

  /// Obtiene el cliente OAuth para hacer llamadas API
  Future<Result<oauth2.Client?>> getClient();
}
