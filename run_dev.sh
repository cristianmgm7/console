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

# Run Flutter with dart-define for each environment variable
# --web-hostname=0.0.0.0 allows external connections (needed for ngrok)
# --web-port sets the port to match ngrok forwarding
# Note: Chrome will open to localhost, but you should navigate to the ngrok URL instead
flutter run -d chrome \
  --web-hostname=0.0.0.0 \
  --web-port=$WEB_PORT \
  --dart-define=OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID" \
  --dart-define=OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
  --dart-define=OAUTH_REDIRECT_URL="$OAUTH_REDIRECT_URL" \
  --dart-define=OAUTH_AUTH_URL="$OAUTH_AUTH_URL" \
  --dart-define=OAUTH_TOKEN_URL="$OAUTH_TOKEN_URL" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
