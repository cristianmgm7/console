#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
else
  echo "Error: .env file not found!"
  echo "Please copy .env.example to .env and fill in your credentials."
  exit 1
fi

# Run Flutter with dart-define for each environment variable
flutter run -d chrome \
  --web-port=8080 \
  --dart-define=OAUTH_CLIENT_ID="$OAUTH_CLIENT_ID" \
  --dart-define=OAUTH_CLIENT_SECRET="$OAUTH_CLIENT_SECRET" \
  --dart-define=OAUTH_REDIRECT_URL="$OAUTH_REDIRECT_URL" \
  --dart-define=OAUTH_AUTH_URL="$OAUTH_AUTH_URL" \
  --dart-define=OAUTH_TOKEN_URL="$OAUTH_TOKEN_URL" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
