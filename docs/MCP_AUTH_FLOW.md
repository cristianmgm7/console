# Flujo Completo de Autenticación MCP

## Cómo DEBE funcionar (paso a paso)

### 1. **El Agente Solicita Autenticación**
- El agente necesita usar un MCP tool que requiere OAuth (ej: GitHub)
- El backend envía un `adk_request_credential` event
- `ChatBloc` recibe el evento y muestra `AuthRequestCard` en el chat

### 2. **Usuario Hace Clic en "Authenticate"**
- Usuario hace clic en el botón "Authenticate" en `AuthRequestCard`
- Se dispara `AuthRequestDetected` event a `McpAuthBloc`
- `McpAuthBloc` almacena el request en `_pendingAuthRequests` usando el `state` como key
- Se emite `McpAuthRequired` state
- Se muestra el `McpAuthenticationDialog`

### 3. **Usuario Hace Clic en "Open Browser to Authenticate"**
- `McpAuthenticationDialog._openAuthUrl()` se ejecuta
- Obtiene la URL de `widget.request.correctedAuthUri`
- Abre el navegador con `launchUrl(uri, mode: LaunchMode.externalApplication)`
- El estado cambia a `_isAuthenticating = true`
- **IMPORTANTE**: El dialog NO se cierra, espera el callback

### 4. **Usuario Completa OAuth en el Navegador**
- El navegador redirige a: `https://cristianmgm7.github.io/carbon-console-auth/?code=XXX&state=YYY`
- La página `web_redirect_page.html` se carga
- JavaScript extrae `code` y `state` de los query parameters
- Construye el deep link: `carbonvoice://auth/callback?code=XXX&state=YYY`
- Redirige al deep link usando `window.location.href = deepLink`

### 5. **macOS Recibe el Deep Link**
- macOS intercepta `carbonvoice://auth/callback?code=XXX&state=YYY`
- `AppDelegate.application(_:open:)` se ejecuta
- Verifica que el scheme sea `carbonvoice`
- Llama al MethodChannel: `methodChannel.invokeMethod("handleDeepLink", arguments: url)`

### 6. **Flutter Recibe el Deep Link**
- `DeepLinkingService._setupMethodChannel()` recibe la llamada
- `_handleDeepLink(url)` se ejecuta
- Busca handlers registrados para el path `/auth/callback`
- **AMBOS handlers se ejecutan**:
  - `AuthBloc` handler: siempre se ejecuta, pero falla si no encuentra el state
  - `McpAuthBloc` handler: verifica si el state está en `_pendingAuthRequests`

### 7. **McpAuthBloc Procesa el Callback**
- `_handleDeepLink()` verifica: `if (state != null && !_pendingAuthRequests.containsKey(state))`
- Si el state NO está en pending requests → retorna (deja que AuthBloc lo maneje)
- Si el state SÍ está → procesa como agent auth
- Extrae `code` y `state` de la URL
- Emite `AuthCodeProvidedFromDeepLink(authorizationCode: code, state: state)`

### 8. **McpAuthBloc Intercambia Code por Tokens**
- `_onAuthCodeProvidedFromDeepLink()` se ejecuta
- Busca el `PendingAuthRequest` usando el state
- Llama a `_completeOAuth2Flow()` para intercambiar code por tokens
- Envía las credenciales al agente via `_sendCredentialsUseCase`
- Emite `McpAuthSuccess` o `McpAuthError`

### 9. **El Dialog se Cierra Automáticamente**
- `AuthRequestCard` tiene un `BlocListener<McpAuthBloc, McpAuthState>`
- Cuando recibe `McpAuthSuccess` o `McpAuthError` → cierra el dialog
- `Navigator.of(dialogContext).pop()`

## Puntos Críticos a Verificar

### ✅ Verificar que el State se Almacene Correctamente
```dart
// En _onAuthRequestDetected:
_storePendingAuthRequest(request.state, request, event.sessionId);
// Debe loggear: "🔐 Storing pending auth request - state: XXX"
```

### ✅ Verificar que el Deep Link se Reciba
```dart
// En AppDelegate (macOS):
print("🔗 AppDelegate received URLs: \(urls)")
// En DeepLinkingService:
_logger.i('📱 Deep link received: $url')
```

### ✅ Verificar que el Handler de MCP se Ejecute
```dart
// En _handleDeepLink de McpAuthBloc:
_logger.i('🔗 Received auth deep link (checking if agent auth): $url')
_logger.i('🔗 State $state not found...') // O
_logger.i('🔗 This is an agent auth request - processing')
```

### ✅ Verificar que el State Coincida
```dart
// El state en el deep link DEBE coincidir con el state almacenado
// Verificar logs: "🔐 Found pending auth request for provider: XXX"
```

## Problemas Comunes

### ❌ El Deep Link No Llega a Flutter
- **Síntoma**: No hay logs de "📱 Deep link received"
- **Causa**: macOS no está registrado para manejar `carbonvoice://`
- **Solución**: Verificar `macos/Runner/Info.plist` tiene `CFBundleURLSchemes`

### ❌ El State No Coincide
- **Síntoma**: Log "State XXX not found in pending agent auth requests"
- **Causa**: El state cambió entre almacenar y recibir el callback
- **Solución**: Verificar que el mismo state se use en toda la cadena

### ❌ El Dialog No Se Cierra
- **Síntoma**: El dialog queda abierto después de autenticar
- **Causa**: `McpAuthSuccess` o `McpAuthError` no se emiten
- **Solución**: Verificar logs del flujo completo

### ❌ El Redirect Page No Redirige
- **Síntoma**: La página se queda en blanco o muestra error
- **Causa**: JavaScript no ejecuta o hay error en el código
- **Solución**: Abrir consola del navegador y verificar errores

## Logs Esperados (en orden)

```
🔐 Received 1 auth requests from ChatBloc
🔐 AUTH REQUEST DETECTED for provider: oauth2
🔐 Authorization URL: https://...
🔐 Storing pending auth request - state: XXX, sessionId: YYY
🔐 Total pending requests: 1
[Usuario hace clic en "Open Browser"]
[Usuario completa OAuth]
🔗 AppDelegate received URLs: [...]
📱 MethodChannel call received - method: handleDeepLink
📱 Deep link received: carbonvoice://auth/callback?code=...&state=XXX
📱 Routing deep link to 2 handler(s) for path: /auth/callback
🔗 Received auth deep link (checking if agent auth): carbonvoice://...
🔗 This is an agent auth request - processing
🔗 Processing agent OAuth callback with state: XXX
🔐 Received auth code from deep link with state: XXX
🔐 Found pending auth request for provider: oauth2
[Intercambio de tokens]
🔐 Successfully authenticated
```

