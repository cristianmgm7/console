# Quick Start Guide

Follow these steps to get your ADK agent running with OAuth2 authentication.

## Step 1: Configure Environment (5 minutes)

```bash
# 1. Navigate to agent directory
cd /Users/cristian/Documents/tech/carbon_voice_console/agent

# 2. Copy environment template
cp .env.example .env

# 3. Generate session keys
echo "SESSION_SECRET_KEY=$(openssl rand -base64 32)" >> .env
echo "TOKEN_ENCRYPTION_KEY=$(openssl rand -base64 32)" >> .env
```

Now edit `.env` and add your credentials:

```bash
# Open in your editor
code .env
# or
nano .env
# or
vim .env
```

**Required:**
- `GOOGLE_API_KEY` - Get from [Google AI Studio](https://aistudio.google.com/apikey)

**For GitHub Integration:**
- `GITHUB_CLIENT_ID` - From [GitHub OAuth Apps](https://github.com/settings/developers)
- `GITHUB_CLIENT_SECRET` - From GitHub OAuth Apps

**For Carbon Voice Integration:**
- `CARBON_CLIENT_ID` - From Carbon Voice developer portal
- `CARBON_CLIENT_SECRET` - From Carbon Voice developer portal

## Step 2: Create GitHub OAuth App (Optional, 3 minutes)

If you want to use the GitHub agent:

1. Go to https://github.com/settings/developers
2. Click "OAuth Apps" → "New OAuth App"
3. Fill in:
   ```
   Application name: Carbon Voice Agent
   Homepage URL: http://localhost:8000
   Authorization callback URL: http://localhost:8000/oauth/callback/github
   ```
4. Click "Register application"
5. Copy the **Client ID** to `.env` → `GITHUB_CLIENT_ID`
6. Click "Generate a new client secret"
7. Copy the **Client Secret** to `.env` → `GITHUB_CLIENT_SECRET`

## Step 3: Start the Server (1 minute)

```bash
# Activate virtual environment
source .venv/bin/activate

# Start the server
python run.py
```

You should see:
```
✅ Configuration validated successfully
🚀 Starting ADK Agent Server on 0.0.0.0:8000

Available endpoints:
  - POST http://localhost:8000/chat/stream
  - GET  http://localhost:8000/oauth/callback/github
  - GET  http://localhost:8000/oauth/callback/carbon
  - GET  http://localhost:8000/session/{session_id}
```

## Step 4: Test the Agent (2 minutes)

### Test 1: Simple Query (No OAuth Required)

```bash
# In a new terminal
curl -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "Hello! What can you help me with?"
  }'
```

Expected output:
```
event: session
data: {"session_id":"...","user_id":"test_user"}

event: message
data: {"content":"I can help you with...","type":"text"}

event: done
data: {"status":"completed"}
```

### Test 2: GitHub Query (Triggers OAuth)

```bash
curl -N -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "message": "List my GitHub repositories"
  }'
```

Expected output:
```
event: session
data: {"session_id":"abc-123-def"}

event: pending_auth
data: {
  "auth_url": "https://github.com/login/oauth/authorize?client_id=...",
  "provider": "github",
  "description": "GitHub OAuth2 Authentication Required",
  "session_id": "abc-123-def"
}
```

**What to do:**
1. Copy the `auth_url` from the response
2. Open it in your browser
3. Authorize the GitHub app
4. You'll be redirected to the callback URL
5. The agent will automatically resume with your GitHub credentials

### Test 3: Using Browser (Easiest)

Save this as `test.html`:

```html
<!DOCTYPE html>
<html>
<head>
    <title>ADK Agent Test</title>
</head>
<body>
    <h1>ADK Agent Test</h1>
    <input type="text" id="message" placeholder="Ask something..." style="width: 500px">
    <button onclick="sendMessage()">Send</button>
    <div id="output"></div>

    <script>
        let sessionId = null;

        function sendMessage() {
            const message = document.getElementById('message').value;
            const output = document.getElementById('output');

            const eventSource = new EventSource(
                'http://localhost:8000/chat/stream',
                {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        user_id: 'test_user',
                        message: message,
                        session_id: sessionId
                    })
                }
            );

            eventSource.addEventListener('session', (e) => {
                const data = JSON.parse(e.data);
                sessionId = data.session_id;
                console.log('Session:', sessionId);
            });

            eventSource.addEventListener('message', (e) => {
                const data = JSON.parse(e.data);
                output.innerHTML += data.content;
            });

            eventSource.addEventListener('pending_auth', (e) => {
                const data = JSON.parse(e.data);
                output.innerHTML += `<p>Auth required: <a href="${data.auth_url}" target="_blank">Click here to authorize ${data.provider}</a></p>`;
            });

            eventSource.addEventListener('done', () => {
                eventSource.close();
            });

            eventSource.addEventListener('error', (e) => {
                console.error('Error:', e);
                eventSource.close();
            });
        }
    </script>
</body>
</html>
```

Open `test.html` in your browser and try:
- "Hello, what can you do?"
- "List my GitHub repositories" (triggers OAuth)
- "Search for Python files in my main repository"

## OAuth Flow Walkthrough

When you ask the agent to do something requiring authentication:

1. **Agent detects missing auth** → Pauses execution
2. **SSE event emitted** → `pending_auth` with OAuth URL
3. **User clicks URL** → Opens GitHub/Carbon authorization page
4. **User approves** → OAuth provider redirects to callback
5. **Callback exchanges code** → Gets access token
6. **Token stored in session** → ADK session state
7. **Agent resumes** → Automatically retries the tool with credentials
8. **Response streamed** → SSE events to client

## Troubleshooting

### Error: "Missing required environment variables"

**Solution:** Make sure `.env` has at least:
```env
GOOGLE_API_KEY=your_actual_key_here
SESSION_SECRET_KEY=some_random_string
```

### Error: "Connection refused" or "Cannot connect"

**Solution:** Make sure the server is running:
```bash
source .venv/bin/activate
python run.py
```

### OAuth callback returns 404

**Solution:** Check that your OAuth app's redirect URI exactly matches:
```
http://localhost:8000/oauth/callback/github
```

### Agent doesn't resume after OAuth

**Solution:**
1. Check server logs for errors
2. Verify token exchange was successful
3. Try with a new session (don't pass `session_id`)

## Next Steps

Now that your agent is running:

1. **Integrate with Flutter app** - Use the `/chat/stream` endpoint with SSE
2. **Add more agents** - Create specialized agents in `src/agents/`
3. **Customize instructions** - Edit agent instructions for your use case
4. **Add tools** - Integrate more MCP tools or custom tools
5. **Production setup** - Configure proper CORS, HTTPS, token encryption

## Project Structure Reference

```
agent/
├── .env                    # Your credentials (create this!)
├── .env.example           # Template
├── run.py                 # Start server with this
├── README.md              # Full documentation
├── QUICKSTART.md          # This file
├── requirements.txt       # Dependencies
├── src/
│   ├── agents/           # Agent definitions
│   │   ├── github_agent.py
│   │   ├── carbon_voice_agent.py
│   │   └── root_agent.py
│   ├── api/              # FastAPI server
│   │   ├── main.py       # Endpoints
│   │   ├── session_manager.py
│   │   ├── agent_runner.py
│   │   └── oauth_handler.py
│   └── config/           # Configuration
│       └── __init__.py
└── tests/                # Tests (to be added)
```

## Common Use Cases

### Use Case 1: GitHub Repository Analysis

```bash
curl -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "developer1",
    "message": "Analyze the code structure of my main repository and suggest improvements"
  }'
```

### Use Case 2: Send Carbon Voice Message

```bash
curl -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "developer1",
    "message": "Send a message to the engineering channel: Daily standup in 10 minutes"
  }'
```

### Use Case 3: Multi-Agent Workflow

```bash
curl -X POST http://localhost:8000/chat/stream \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "developer1",
    "message": "Create a GitHub issue for the bug I just described, then send a Carbon Voice message to the team about it"
  }'
```

The root orchestrator will automatically delegate to both agents!

---

**Need help?** Check the [full README](README.md) for detailed documentation.
