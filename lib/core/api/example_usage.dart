// Ejemplo de uso de los DTOs generados de la API ADK
import 'package:carbon_voice_console/core/api/generated/lib/api.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/event.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/run_agent_request.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/content.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/content_parts_inner.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/create_session_request.dart';
import 'package:carbon_voice_console/core/api/generated/lib/model/session.dart';

class AdkApiExample {
  final DefaultApi api = DefaultApi();

  // Ejemplo de cómo crear una sesión
  Future<Session?> createSession({
    required String appName,
    required String userId,
    String? sessionId,
  }) async {
    final request = CreateSessionRequest(
      sessionId: sessionId,
      state: {},
      events: [],
    );

    try {
      return await api.appsAppNameUsersUserIdSessionsPost(
        appName,
        userId,
        createSessionRequest: request,
      );
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  // Ejemplo de cómo ejecutar un agente
  Future<List<Event>?> runAgent({
    required String appName,
    required String userId,
    required String sessionId,
    required String message,
    bool streaming = false,
  }) async {
    // Crear el contenido del mensaje
    final contentPart = ContentPartsInner(text: message);
    final content = Content(
      role: Content.RoleEnum.user,
      parts: [contentPart],
    );

    final request = RunAgentRequest(
      appName: appName,
      userId: userId,
      sessionId: sessionId,
      newMessage: content,
      streaming: streaming,
    );

    try {
      return await api.runPost(runAgentRequest: request);
    } catch (e) {
      print('Error running agent: $e');
      return null;
    }
  }

  // Ejemplo de cómo listar agentes
  Future<List<String>?> listApps({bool detailed = false}) async {
    try {
      final response = await api.listAppsGet(detailed: detailed);
      // La respuesta puede ser List<String> o ListAppsResponse dependiendo del parámetro detailed
      if (response is List<String>) {
        return response;
      } else if (response is ListAppsResponse) {
        return response.apps?.map((app) => app.name ?? '').toList();
      }
      return null;
    } catch (e) {
      print('Error listing apps: $e');
      return null;
    }
  }
}
