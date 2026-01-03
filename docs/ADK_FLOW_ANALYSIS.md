# Análisis del Flujo ADK y Estrategia de UI

## 🔍 Cómo Funciona el Flujo ADK

### Estructura de un Evento ADK

Cada evento que llega del backend tiene esta estructura:

```typescript
{
  id: string,
  invocationId: string,
  author: string,  // Ej: "agent:github", "agent:carbon_voice"
  timestamp: number,
  partial: boolean,  // true si es streaming parcial
  content: {
    role: string,
    parts: [  // CONTENIDO PRINCIPAL
      { text: "..." },  // Texto del agente
      { functionCall: { name: "...", args: {...} } },  // Llamada a tool
      { functionResponse: { name: "...", response: {...} } },  // Respuesta de tool
    ]
  },
  actions: {  // ACCIONES REQUERIDAS (OPCIONAL)
    requestedAuthConfigs: {...},  // OAuth necesario
    requestedToolConfirmations: {...},  // Confirmación de usuario necesaria
    stateDelta: {...},  // Cambios de estado interno
    artifactDelta: {...},  // Cambios en archivos
    transferToAgent: "..."  // Transferir a otro agente
  }
}
```

### Flujo Típico de Eventos

#### Escenario 1: Mensaje Simple
```
Evento 1:
  content.parts = [{ text: "Hola, ¿cómo puedo ayudarte?" }]
  actions = null
```
✅ **Mostrar:** El texto directamente en la UI

---

#### Escenario 2: Function Call Sin Acciones
```
Evento 1:
  content.parts = [{ functionCall: { name: "search_github", args: {...} } }]
  actions = null

Evento 2:
  content.parts = [{ functionResponse: { name: "search_github", response: {...} } }]
  actions = null

Evento 3:
  content.parts = [{ text: "Encontré estos repositorios..." }]
  actions = null
```
✅ **Mostrar:** 
- Evento 1: Indicador de "Buscando en GitHub..." (temporal)
- Evento 2: Remover el indicador
- Evento 3: El texto con los resultados

❌ **NO Mostrar:** Los detalles internos del function call/response

---

#### Escenario 3: Function Call Que Requiere Auth (TU CASO)
```
Evento 1:
  content.parts = [{ functionCall: { name: "create_issue", args: {...} } }]
  actions = {
    requestedAuthConfigs: {
      "github": {
        authScheme: { ... },
        rawAuthCredential: { oauth2: {...} }
      }
    }
  }
```

⚠️ **PROBLEMA ACTUAL:** Tu código está emitiendo DOS eventos categorizados:
1. `FunctionCallEvent` → Muestra "Calling create_issue..."
2. `AuthenticationRequestEvent` → Muestra tarjeta de OAuth

**SOLUCIÓN:** Cuando un evento tiene AMBOS (functionCall + requestedAuthConfigs), deberías:
- **OCULTAR** el FunctionCallEvent (el indicador de "pensando")
- **MOSTRAR SOLO** el AuthenticationRequestEvent (la tarjeta de OAuth)

**Razón:** El usuario no necesita ver "Llamando a create_issue..." si inmediatamente después verá una tarjeta diciendo "Necesitas autenticarte con GitHub". Es redundante y confuso.

---

#### Escenario 4: Function Call Que Requiere Confirmación
```
Evento 1:
  content.parts = [{ functionCall: { name: "delete_repository", args: {...} } }]
  actions = {
    requestedToolConfirmations: {
      "call_123": {
        name: "delete_repository",
        args: { repo: "mi-repo" }
      }
    }
  }
```

Similar al escenario 3:
- **OCULTAR** el FunctionCallEvent
- **MOSTRAR SOLO** el ToolConfirmationEvent (tarjeta de confirmación)

---

## ✅ Qué DEBE Mostrarse en la UI

### 1. **Mensajes de Texto del Agente**
```dart
ChatMessageEvent → TextMessageItem
```
- Cualquier texto que el agente envíe al usuario
- Incluye respuestas, explicaciones, resultados
- **Ejemplo:** "He creado el issue #123 en GitHub"

### 2. **Solicitudes de Autenticación**
```dart
AuthenticationRequestEvent → AuthRequestItem
```
- Tarjetas interactivas con botón "Authenticate"
- Muestra el proveedor (GitHub, Atlassian, etc.)
- **Ejemplo:** Card con "GitHub Authentication Required"

### 3. **Solicitudes de Confirmación**
```dart
ToolConfirmationEvent → ToolConfirmationItem
```
- Tarjetas interactivas con botones "Confirm" / "Cancel"
- Muestra qué acción se va a ejecutar y con qué parámetros
- **Ejemplo:** "¿Deseas eliminar el repositorio 'mi-repo'?"

### 4. **Indicadores de Estado Temporales**
```dart
FunctionCallEvent → SystemStatusItem (temporal)
```
- "Pensando..." o "Llamando a X..."
- Se muestra mientras el tool se ejecuta
- Se REMUEVE cuando llega el FunctionResponseEvent
- **IMPORTANTE:** Solo si NO hay actions que requieran interacción del usuario

### 5. **Errores**
```dart
AgentErrorEvent → SystemStatusItem (error)
```
- Errores que el usuario debe ver
- **Ejemplo:** "Failed to connect to GitHub API"

---

## ❌ Qué NO Debe Mostrarse en la UI

### 1. **State Deltas** (Estado Interno del Agente)
```dart
StateUpdateEvent → NO MOSTRAR
```
- Son cambios internos del estado del agente
- El usuario no necesita verlos
- Se guardan en `ChatLoaded.agentState` pero no se visualizan

### 2. **Artifact Deltas** (Cambios en Archivos)
```dart
ArtifactUpdateEvent → NO MOSTRAR (por ahora)
```
- Son cambios en archivos que el agente está manejando
- En el futuro podrías mostrarlos en un panel separado
- Por ahora, guárdalos en `ChatLoaded.artifacts`

### 3. **Function Responses** (Respuestas de Tools)
```dart
FunctionResponseEvent → NO MOSTRAR como mensaje
```
- Solo úsalos para REMOVER el indicador de "pensando"
- El usuario no necesita ver los datos crudos del response
- El agente procesará el response y enviará un mensaje de texto

### 4. **Function Calls Cuando Hay Actions Requeridas**
```dart
FunctionCallEvent → NO MOSTRAR si actions != null
```
- Si el evento tiene `requestedAuthConfigs` o `requestedToolConfirmations`
- Muestra solo la acción requerida, no el indicador de "pensando"

---

## 🔧 Correcciones Necesarias en el Código

### Problema en `GetChatMessagesFromEventsUseCase`

**Líneas 108-117:**
```dart
// Problema: Siempre emite FunctionCallEvent
for (final part in event.content.parts) {
  if (part is AdkFunctionCallPart) {
    _logger.d('Function call: ${part.name}');
    sink.add(FunctionCallEvent(
      sourceEvent: event,
      functionName: part.name,
      args: part.args,
    ));
  }
```

**Solución:** Verificar si el evento requiere acciones del usuario antes de emitir:

```dart
// Verificar si este evento requiere acciones del usuario
final requiresUserAction = event.isAuthenticationRequest || 
                           (event.actions?.requestedToolConfirmations != null);

// Solo mostrar indicador de "pensando" si NO requiere acción del usuario
if (!requiresUserAction) {
  for (final part in event.content.parts) {
    if (part is AdkFunctionCallPart) {
      _logger.d('Function call: ${part.name}');
      sink.add(FunctionCallEvent(
        sourceEvent: event,
        functionName: part.name,
        args: part.args,
      ));
    }
  }
}
```

---

## 📊 Flujo Correcto de Mapeo

```
ADK Event Stream
     ↓
GetChatMessagesFromEventsUseCase
     ↓
Categorización (con lógica de prioridad):
     ↓
1. ¿Tiene requestedAuthConfigs? 
   → AuthenticationRequestEvent
   → SKIP FunctionCallEvent
     ↓
2. ¿Tiene requestedToolConfirmations?
   → ToolConfirmationEvent
   → SKIP FunctionCallEvent
     ↓
3. ¿Tiene FunctionCallPart y NO requiere acciones?
   → FunctionCallEvent (temporal)
     ↓
4. ¿Tiene FunctionResponsePart?
   → FunctionResponseEvent (remueve indicador)
     ↓
5. ¿Tiene TextPart?
   → ChatMessageEvent
     ↓
6. ¿Tiene stateDelta?
   → StateUpdateEvent (guardar, no mostrar)
     ↓
7. ¿Tiene artifactDelta?
   → ArtifactUpdateEvent (guardar, no mostrar)
     ↓
ChatBloc
     ↓
Convierte a ChatItems para UI
     ↓
Render en ChatScreen
```

---

## 🎯 Resumen: ¿Qué es Relevante en la UI?

### ✅ RELEVANTE (Mostrar)
1. **Mensajes de texto del agente** - El usuario necesita leerlos
2. **Solicitudes de OAuth** - El usuario debe autenticarse
3. **Solicitudes de confirmación** - El usuario debe aprobar acciones
4. **Indicadores temporales de "pensando"** - Solo cuando NO hay acciones requeridas
5. **Errores** - El usuario debe saber qué salió mal

### ❌ NO RELEVANTE (Ocultar)
1. **State deltas** - Detalles internos del agente
2. **Artifact deltas** - Archivos (mostrar en panel separado en el futuro)
3. **Function responses** - Datos crudos procesados por el agente
4. **Function calls cuando hay actions** - Redundante con las tarjetas de acción

---

## 🔑 Regla de Oro

> **Si un evento tiene `actions` que requieren interacción del usuario (auth/confirmación), NO muestres los indicadores de "pensando" para ese evento. El usuario solo debe ver la tarjeta de acción.**

---

## 📝 Próximos Pasos

1. ✅ Actualizar `GetChatMessagesFromEventsUseCase` para no emitir `FunctionCallEvent` cuando hay actions
2. ✅ Validar que `StateUpdateEvent` y `ArtifactUpdateEvent` NO se muestren en el chat
3. ⚠️ Considerar agregar un panel de "Debug" que muestre todos los eventos (para desarrollo)
4. ⚠️ En el futuro, considerar mostrar `ArtifactUpdateEvent` en un panel de "Files" separado

---

## 🧪 Cómo Validar

### Test Case 1: Auth Flow
```
User: "Create an issue in GitHub"
Expected UI:
1. User message bubble
2. Auth card (if not authenticated)
3. Agent message with confirmation

NOT Expected:
❌ "Calling create_issue..." indicator
```

### Test Case 2: Tool Confirmation
```
User: "Delete my repository"
Expected UI:
1. User message bubble
2. Confirmation card "Delete repository X?"
3. Agent message with result

NOT Expected:
❌ "Calling delete_repository..." indicator
```

### Test Case 3: Normal Tool Call
```
User: "Search repositories"
Expected UI:
1. User message bubble
2. ✅ "Searching repositories..." (temporal)
3. Agent message with results

This is OK because no user action is required.
```

