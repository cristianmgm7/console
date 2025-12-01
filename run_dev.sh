#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
else
  echo "Error: .env file not found!"
  echo "Please copy .env.example to .env and fill in your credentials."
  exit 1
fi

# Extract port from redirect URL if it contains a port number
# Default to 65456 if not specified
WEB_PORT=${WEB_PORT:-3000}

echo "🐛 Running Flutter web app in DEBUG mode..."
echo ""

# Check if ngrok is running and get the URL
NGROK_URL=""
NGROK_RUNNING=false

if pgrep -x "ngrok" > /dev/null; then
  echo "✅ ngrok está corriendo"
  NGROK_RUNNING=true
  # Try to get ngrok URL from API (if available)
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"[^"]*' | head -1 | cut -d'"' -f4 || echo "")
  if [ -n "$NGROK_URL" ]; then
    echo "   URL de ngrok: $NGROK_URL"
  fi
else
  echo "⚠️  ngrok NO está corriendo"
  echo "   Para que OAuth funcione, debes iniciar ngrok en otra terminal:"
  echo "   ngrok http $WEB_PORT --domain=carbonconsole.ngrok.app"
  echo ""
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🚀 MODO DEBUG CON LOGS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📝 Verás TODOS los logs aquí en esta terminal"
echo ""
echo "📍 ACCEDE A LA APP:"
if [ "$NGROK_RUNNING" = true ]; then
  echo ""
  echo "   ✅ $NGROK_URL"
  echo ""
  echo "   ✅ OAuth funcionará correctamente"
  echo "   ✅ Verás todos los logs en esta terminal"
  echo "   ✅ Hot reload funcionará (presiona 'r')"
  echo ""
else
  echo ""
  echo "   http://localhost:$WEB_PORT"
  echo ""
  echo "   ⚠️  Sin ngrok, OAuth NO funcionará"
  echo ""
fi
echo "═══════════════════════════════════════════════════════════"
echo "Press Ctrl+C to stop"
echo ""

# Run Flutter web in debug mode with Chrome
# Flutter abrirá Chrome automáticamente con localhost
# IMPORTANTE: Cuando Chrome se abra, cambia la URL de localhost a la URL de ngrok
if [ "$NGROK_RUNNING" = true ]; then
  echo "💡 IMPORTANTE: Chrome se abrirá con localhost"
  echo "   👉 En la MISMA pestaña que se abre, cambia la URL a:"
  echo "   👉 $NGROK_URL"
  echo ""
  echo "   (Esto mantiene la conexión de debug de Flutter)"
  echo ""
  sleep 3
fi

flutter run -d chrome \
  --web-hostname=0.0.0.0 \
  --web-port=$WEB_PORT \
  --dart-define=OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID" \
  --dart-define=OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
  --dart-define=OAUTH_REDIRECT_URL="$OAUTH_REDIRECT_URL" \
  --dart-define=OAUTH_AUTH_URL="$OAUTH_AUTH_URL" \
  --dart-define=OAUTH_TOKEN_URL="$OAUTH_TOKEN_URL" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
