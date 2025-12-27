# ADK Agent with OAuth2 Authentication

A clean implementation of Google Agent Development Kit (ADK) agents with native OAuth2 authentication for GitHub and Carbon Voice integrations.

## Architecture

This implementation uses **ADK's native authentication** without external OAuth proxies:

- **GitHub Agent**: Repository management, issues, PRs with GitHub OAuth2
- **Carbon Voice Agent**: Messaging platform operations with Carbon Voice OAuth2
- **Root Orchestrator**: Coordinates both agents based on user intent
- **FastAPI Server**: SSE streaming with OAuth event handling
- **ADK Session Management**: Token storage and automatic refresh

## Project Structure

```
agent/
├── .venv/                  # Python virtual environment
├── requirements.txt        # Python dependencies
├── .env.example           # Environment template
├── .env                   # Your credentials (create from .env.example)
├── src/
│   ├── agents/
│   │   ├── github_agent.py        # GitHub agent with OAuth2
│   │   ├── carbon_voice_agent.py  # Carbon Voice agent with OAuth2
│   │   └── root_agent.py          # Orchestrator agent
│   ├── api/
│   │   ├── main.py                # FastAPI server
│   │   ├── session_manager.py     # ADK session management
│   │   ├── agent_runner.py        # SSE streaming
│   │   └── oauth_handler.py       # Token exchange
│   └── config/
│       └── __init__.py            # Configuration management
└── tests/
```

## Setup Instructions

### 1. Configure Environment

Copy the example environment file and fill in your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
# Google ADK Configuration
GOOGLE_API_KEY=your_gemini_api_key_here

# GitHub OAuth2 Configuration
GITHUB_CLIENT_ID=your_github_oauth_app_client_id
GITHUB_CLIENT_SECRET=your_github_oauth_app_client_secret
GITHUB_REDIRECT_URI=http://localhost:8000/oauth/callback/github

# Carbon Voice OAuth2 Configuration
CARBON_CLIENT_ID=your_carbon_oauth_client_id
CARBON_CLIENT_SECRET=your_carbon_oauth_client_secret
CARBON_REDIRECT_URI=http://localhost:8000/oauth/callback/carbon

# Session Configuration
SESSION_SECRET_KEY=$(openssl rand -base64 32)
TOKEN_ENCRYPTION_KEY=$(openssl rand -base64 32)
```

### 2. Create OAuth Applications

#### GitHub OAuth App

1. Go to GitHub Settings > Developer settings > OAuth Apps
2. Click "New OAuth App"
3. Fill in:
   - Application name: `Carbon Voice Agent`
   - Homepage URL: `http://localhost:8000`
   - Authorization callback URL: `http://localhost:8000/oauth/callback/github`
4. Copy the Client ID and generate a Client Secret
5. Add to `.env` file

#### Carbon Voice OAuth App

1. Contact Carbon Voice support or check their developer portal
2. Create an OAuth application
3. Set redirect URI to: `http://localhost:8000/oauth/callback/carbon`
4. Copy credentials to `.env` file

### 3. Generate Session Keys

Generate secure random keys for session management:

```bash
# On macOS/Linux
echo "SESSION_SECRET_KEY=$(openssl rand -base64 32)" >> .env
echo "TOKEN_ENCRYPTION_KEY=$(openssl rand -base64 32)" >> .env
```

### 4. Activate Virtual Environment

```bash
cd /Users/cristian/Documents/tech/carbon_voice_console/agent
source .venv/bin/activate
```

### 5. Run the Server

```bash
# Development mode with auto-reload
python src/api/main.py

# Or using uvicorn directly
uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload
```

The server will start at `http://localhost:8000`

## API Endpoints

### Chat with Agent (SSE Stream)

```bash
POST /chat/stream
Content-Type: application/json

{
  "user_id": "user123",
  "message": "List my GitHub repositories",
  "session_id": "optional-session-id"
}
```

**SSE Events:**
- `session`: Session information
- `message`: Agent response chunks
- `pending_auth`: OAuth required (contains auth_url)
- `done`: Agent execution completed
- `error`: Error occurred

### OAuth Callback

```bash
GET /oauth/callback/{provider}?code=xxx&session_id=xxx
```

Handled automatically by OAuth providers after user authorization.

### Session Management

```bash
# Get session info
GET /session/{session_id}

# Delete session
DELETE /session/{session_id}
```

## OAuth Flow

1. **User sends message** to `/chat/stream`
2. **Agent starts processing**, session created
3. **Auth required**: Agent detects missing OAuth token
4. **SSE event emitted**: `pending_auth` with `auth_url`
5. **User authorizes** via OAuth URL in browser
6. **OAuth callback** exchanges code for token
7. **Token stored** in ADK session state
8. **Agent resumes** automatically with credentials
9. **Token refresh**: Automatic when expired

## Key Features

### ADK Native Authentication

- No external OAuth proxy needed
- Built-in token refresh with `Credentials.refresh(Request())`
- Session-based token storage
- Per-user, per-session credentials

### SSE Streaming

- Real-time agent responses
- OAuth event detection
- Error handling and recovery

### Multi-Agent Orchestration

- Root agent routes to specialized agents
- Transparent sub-agent authentication
- Coordinated workflows

## Testing

Test the agent with curl:

```bash
# Start SSE stream
curl -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "What GitHub repositories do I have access to?"
  }'
```

You'll receive:
1. `session` event with session_id
2. `pending_auth` event with GitHub OAuth URL
3. Complete OAuth in browser
4. Agent resumes and streams response

## Architecture Highlights

### No Stytch Dependency

Original implementation used Stytch as OAuth proxy. This version uses ADK's native OAuth2 capabilities:

- `tool_context.request_credential()` for OAuth initiation
- `tool_context.get_auth_response()` for token retrieval
- `google.oauth2.credentials.Credentials` for token management
- Automatic token refresh when expired

### Session State Management

```python
# Tokens stored in session.state
session.state["github_oauth_token"] = json.dumps({
    "token": "access_token_here",
    "refresh_token": "refresh_token_here",
    "token_type": "Bearer"
})

# ADK auto-refreshes when expired
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
```

### Agent Auth Callbacks

Each agent has an `auth_callback` function:

```python
def github_auth_callback(tool_context):
    # Check session for existing token
    # Refresh if expired
    # Request OAuth if missing
    # Return credentials for tools
```

## Troubleshooting

### Missing Environment Variables

```
ValueError: Missing required environment variables: GOOGLE_API_KEY
```

**Solution**: Copy `.env.example` to `.env` and fill in all required values.

### OAuth Callback 404

**Problem**: OAuth redirect fails with 404

**Solution**: Ensure redirect URIs in OAuth app settings match exactly:
- GitHub: `http://localhost:8000/oauth/callback/github`
- Carbon: `http://localhost:8000/oauth/callback/carbon`

### Token Refresh Fails

**Problem**: Expired tokens not refreshing

**Solution**: Check that OAuth scopes include offline access and refresh tokens are being issued.

## Next Steps

- [ ] Add token encryption for production
- [ ] Implement rate limiting
- [ ] Add comprehensive logging
- [ ] Set up production deployment configuration
- [ ] Add integration tests
- [ ] Configure CORS for production domains
