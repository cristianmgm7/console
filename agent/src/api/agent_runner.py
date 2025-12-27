"""Agent execution with SSE streaming and OAuth event detection."""

import asyncio
import json
from typing import AsyncGenerator, Dict, Any
from google.adk.agents import Agent
from google.adk.runners import InvocationContext

from src.api.session_manager import session_manager


class AgentRunner:
    """
    Runs ADK agents with SSE streaming support.

    Handles:
    - Agent execution with streaming responses
    - OAuth authentication event detection
    - Session state management
    """

    def __init__(self, agent: Agent):
        """
        Initialize agent runner.

        Args:
            agent: The ADK agent to run
        """
        self.agent = agent

    async def run_stream(
        self,
        user_id: str,
        message: str,
        session_id: str = None
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Execute agent and stream responses via SSE.

        Args:
            user_id: User identifier for session management
            message: User message to process
            session_id: Optional session ID to resume

        Yields:
            SSE events as dicts with 'event' and 'data' keys
        """
        # Get or create session
        session = session_manager.get_or_create_session(user_id, session_id)

        # Create invocation context
        context = InvocationContext(
            session=session,
            user_message=message
        )

        try:
            # Send session info event
            yield {
                "event": "session",
                "data": json.dumps({
                    "session_id": session.session_id,
                    "user_id": user_id
                })
            }

            # Execute agent with streaming
            async for chunk in self.agent.run_stream(context):
                # Check for authentication requests in chunk
                if self._is_auth_request(chunk):
                    auth_event = self._extract_auth_event(chunk)
                    yield {
                        "event": "pending_auth",
                        "data": json.dumps(auth_event)
                    }
                    # Agent execution is paused, waiting for OAuth callback
                    return

                # Regular streaming response
                yield {
                    "event": "message",
                    "data": json.dumps({
                        "content": chunk.get("content", ""),
                        "type": chunk.get("type", "text")
                    })
                }

            # Agent execution completed
            yield {
                "event": "done",
                "data": json.dumps({"status": "completed"})
            }

        except Exception as e:
            # Error during execution
            yield {
                "event": "error",
                "data": json.dumps({
                    "error": str(e),
                    "type": type(e).__name__
                })
            }

    def _is_auth_request(self, chunk: Dict[str, Any]) -> bool:
        """
        Detect if chunk contains an authentication request.

        ADK emits special events when request_credential() is called.

        Args:
            chunk: Streaming response chunk

        Returns:
            True if chunk contains auth request
        """
        # Check for ADK auth request indicator
        # This might be in chunk metadata or event type
        if chunk.get("event_type") == "auth_required":
            return True

        # Check for auth request in metadata
        metadata = chunk.get("metadata", {})
        if metadata.get("requires_auth"):
            return True

        return False

    def _extract_auth_event(self, chunk: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract OAuth details from auth request chunk.

        Args:
            chunk: Chunk containing auth request

        Returns:
            Dict with auth_url, provider, description
        """
        # Extract auth URL and provider from chunk
        # Format depends on ADK's event structure
        auth_info = chunk.get("auth_info", {})

        return {
            "auth_url": auth_info.get("auth_url"),
            "provider": auth_info.get("provider"),
            "description": auth_info.get("description", "Authentication required"),
            "session_id": chunk.get("session_id")
        }

    def resume_after_auth(
        self,
        session_id: str,
        provider: str,
        auth_code: str
    ) -> Dict[str, Any]:
        """
        Resume agent execution after OAuth callback.

        This is called by the OAuth callback endpoint after the user
        completes authentication. It exchanges the auth code for tokens
        and stores them in the session.

        Args:
            session_id: Session to resume
            provider: OAuth provider (github, carbon)
            auth_code: Authorization code from OAuth callback

        Returns:
            Result dict with status
        """
        session = session_manager.get_session(session_id)
        if not session:
            return {"error": "Session not found"}

        # Exchange auth code for tokens
        # This depends on the provider
        from src.api.oauth_handler import exchange_code_for_token

        token_data = exchange_code_for_token(provider, auth_code)

        if "error" in token_data:
            return token_data

        # Store tokens in session state
        token_key = f"{provider}_oauth_token"
        session.state[token_key] = json.dumps(token_data)

        # Signal ADK that authentication is complete
        # ADK will resume agent execution automatically
        return {
            "status": "success",
            "session_id": session_id,
            "message": "Authentication successful, resuming agent"
        }
