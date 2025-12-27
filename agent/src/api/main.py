"""FastAPI server with SSE streaming for ADK agents."""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional
import json

from src.config import config
from src.agents import root_agent
from src.api.agent_runner import AgentRunner
from src.api.oauth_handler import exchange_code_for_token
from src.api.session_manager import session_manager


# Validate configuration on startup
config.validate()

# Initialize FastAPI app
app = FastAPI(
    title="ADK Agent API",
    description="FastAPI server with SSE streaming for Google ADK agents with OAuth2 authentication",
    version="1.0.0"
)

# CORS middleware for Flutter web/mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize agent runner with root orchestrator
agent_runner = AgentRunner(root_agent)


# Request/Response models
class ChatRequest(BaseModel):
    """Request model for chat endpoint."""
    user_id: str
    message: str
    session_id: Optional[str] = None


class OAuthCallbackRequest(BaseModel):
    """Request model for OAuth callback."""
    session_id: str
    provider: str
    code: str
    state: Optional[str] = None


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "ADK Agent API",
        "version": "1.0.0"
    }


@app.post("/chat/stream")
async def chat_stream(request: ChatRequest):
    """
    Chat endpoint with SSE streaming.

    Executes the root orchestrator agent and streams responses.
    Handles OAuth authentication events transparently.

    Args:
        request: ChatRequest with user_id, message, optional session_id

    Returns:
        StreamingResponse with SSE events
    """

    async def event_stream():
        """Generate SSE events from agent execution."""
        try:
            async for event in agent_runner.run_stream(
                user_id=request.user_id,
                message=request.message,
                session_id=request.session_id
            ):
                # Format as SSE
                event_type = event.get("event", "message")
                event_data = event.get("data", "{}")

                yield f"event: {event_type}\n"
                yield f"data: {event_data}\n\n"

        except Exception as e:
            # Error event
            error_data = json.dumps({
                "error": str(e),
                "type": type(e).__name__
            })
            yield f"event: error\n"
            yield f"data: {error_data}\n\n"

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )


@app.post("/oauth/callback/{provider}")
async def oauth_callback(
    provider: str,
    code: str = Query(...),
    state: Optional[str] = Query(None),
    session_id: str = Query(...)
):
    """
    OAuth callback endpoint.

    Called by OAuth provider after user authorization.
    Exchanges code for token and resumes agent execution.

    Args:
        provider: OAuth provider (github, carbon)
        code: Authorization code
        state: Optional state parameter
        session_id: Session to resume

    Returns:
        Redirect or status response
    """
    # Exchange code for token
    token_data = exchange_code_for_token(provider, code)

    if "error" in token_data:
        raise HTTPException(
            status_code=400,
            detail=f"OAuth token exchange failed: {token_data['error']}"
        )

    # Get session
    session = session_manager.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    # Store tokens in session state
    token_key = f"{provider}_oauth_token"
    session.state[token_key] = json.dumps(token_data)

    # Return success - Flutter client will resume SSE stream
    return {
        "status": "success",
        "provider": provider,
        "session_id": session_id,
        "message": f"{provider.title()} authentication successful"
    }


@app.get("/session/{session_id}")
async def get_session(session_id: str):
    """
    Get session information.

    Args:
        session_id: Session ID

    Returns:
        Session data (without sensitive tokens)
    """
    session = session_manager.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    return {
        "session_id": session.session_id,
        "user_id": session.state.get("user_id"),
        "has_github_auth": "github_oauth_token" in session.state,
        "has_carbon_auth": "carbon_oauth_token" in session.state
    }


@app.delete("/session/{session_id}")
async def delete_session(session_id: str):
    """
    Delete a session.

    Args:
        session_id: Session ID to delete

    Returns:
        Confirmation
    """
    session_manager.delete_session(session_id)
    return {"status": "deleted", "session_id": session_id}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "src.api.main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG
    )
