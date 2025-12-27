"""ADK session manager for multi-user agent sessions."""

from typing import Dict, Optional
from google.adk.sessions import InMemorySessionService
import uuid


class SessionManager:
    """
    Manages ADK sessions for multiple users.

    Each user can have multiple sessions (e.g., different conversations).
    Sessions store OAuth tokens and conversation state.
    """

    def __init__(self):
        """Initialize the session manager with in-memory storage."""
        # ADK's built-in session service
        self.session_service = InMemorySessionService()

        # Track active sessions by user_id -> session_id
        self.user_sessions: Dict[str, str] = {}

    def get_or_create_session(self, user_id: str, session_id: Optional[str] = None):
        """
        Get an existing session or create a new one for a user.

        Args:
            user_id: Unique user identifier
            session_id: Optional session ID (creates new if None)

        Returns:
            ADK Session object
        """
        if session_id:
            # Resume existing session
            session = self.session_service.get_session(session_id)
            if session:
                return session

        # Create new session
        new_session_id = session_id or str(uuid.uuid4())
        session = self.session_service.create_session(new_session_id)

        # Initialize session state with user_id
        session.state["user_id"] = user_id

        # Track session for this user
        self.user_sessions[user_id] = new_session_id

        return session

    def get_session(self, session_id: str):
        """Get a session by ID."""
        return self.session_service.get_session(session_id)

    def delete_session(self, session_id: str):
        """Delete a session and clean up user tracking."""
        session = self.session_service.get_session(session_id)
        if session:
            user_id = session.state.get("user_id")
            if user_id and self.user_sessions.get(user_id) == session_id:
                del self.user_sessions[user_id]

        self.session_service.delete_session(session_id)

    def get_user_session_id(self, user_id: str) -> Optional[str]:
        """Get the active session ID for a user."""
        return self.user_sessions.get(user_id)


# Global session manager instance
session_manager = SessionManager()
