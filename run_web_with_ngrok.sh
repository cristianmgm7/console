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
# Default to 65456 if not specified (or use the port ngrok is forwarding to)
WEB_PORT=${WEB_PORT:-65456}

echo "🔨 Building Flutter web app..."
echo ""

# Build Flutter web app with dart-define for each environment variable
flutter build web \
  --dart-define=OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID" \
  --dart-define=OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
  --dart-define=OAUTH_REDIRECT_URL="$OAUTH_REDIRECT_URL" \
  --dart-define=OAUTH_AUTH_URL="$OAUTH_AUTH_URL" \
  --dart-define=OAUTH_TOKEN_URL="$OAUTH_TOKEN_URL" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "🚀 Starting HTTP server on port $WEB_PORT..."
echo "📱 Access the app at: http://localhost:$WEB_PORT"
echo "🌐 Or through ngrok: https://carbonconsole.ngrok.app"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Get the absolute path to the build/web directory
BUILD_WEB_DIR="$(pwd)/build/web"

# Use custom Python server that supports SPA routing (serves index.html for all routes)
if command -v python3 &> /dev/null; then
  python3 serve_web.py $WEB_PORT "$BUILD_WEB_DIR"
elif command -v python &> /dev/null; then
  python serve_web.py $WEB_PORT "$BUILD_WEB_DIR"
else
  echo "❌ Error: Python is not installed. Please install Python to serve the web app."
  echo "Alternatively, you can use any HTTP server to serve the build/web/ directory"
  exit 1
fi

