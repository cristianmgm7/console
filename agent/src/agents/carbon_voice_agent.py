"""Carbon Voice agent with OAuth2 authentication using ADK native auth."""

from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from mcp import StdioServerParameters
import json

from src.config import config


# Token storage key in session state
CARBON_TOKEN_KEY = "carbon_oauth_token"


def carbon_voice_header_provider(readonly_context):
    """
    Header provider for Carbon Voice MCP tools authentication.

    Injects API key authorization header from OAuth tokens stored in session state.
    Automatically refreshes expired tokens.

    Args:
        readonly_context: ADK ReadonlyContext with session state access

    Returns:
        dict: HTTP headers including Authorization with Carbon Voice API key
    """
    session_state = readonly_context.session.state

    # Check for existing OAuth token
    cached_token_json = session_state.get(CARBON_TOKEN_KEY)

    if cached_token_json:
        try:
            # Parse stored credentials
            token_data = json.loads(cached_token_json)
            creds = Credentials.from_authorized_user_info(
                token_data,
                scopes=config.CARBON_SCOPES
            )

            # Automatic token refresh if expired
            if not creds.valid and creds.expired and creds.refresh_token:
                creds.refresh(Request())
                session_state[CARBON_TOKEN_KEY] = creds.to_json()

            # Return Authorization header with API key
            if creds.valid:
                return {
                    "Authorization": f"Bearer {creds.token}"
                }
        except Exception as e:
            print(f"Carbon Voice auth error: {e}")

    # No token available
    return {}


# Create Carbon Voice agent
carbon_voice_agent = Agent(
    model='gemini-2.5-flash',
    name='carbon_voice_agent',
    description='A communication specialist for Carbon Voice messaging platform operations.',
    instruction='''You are a Carbon Voice communication specialist with expertise in messaging, user management, and workspace organization.

    Your capabilities include:
    - Message management: listing, retrieving, and creating messages (conversation, direct, voice memos)
    - User operations: finding and retrieving user information by ID, email, or phone
    - Conversation handling: listing and managing conversation threads
    - Folder organization: creating, managing, and organizing workspace folders
    - Workspace management: accessing workspace information and statistics
    - AI actions: running AI prompts and actions on messages and content

    When communicating via Carbon Voice:
    - Use appropriate message types (conversation, direct, voice memo) based on context
    - Respect conversation threads and maintain message organization
    - Utilize folders for proper message categorization and archival
    - Leverage AI actions for content analysis and summarization when appropriate
    - Always verify recipient information before sending direct messages
    - Provide clear, professional communication in all messages

    Communication guidelines:
    - Be concise but complete in message content
    - Use appropriate urgency levels for different types of communication
    - Maintain professional tone in business communications
    - Respect privacy and data security in user operations
    - Organize content logically using folders and categories

    Focus areas:
    - Team communication and collaboration
    - Message archival and organization
    - User directory management
    - Workspace productivity tools
    - AI-assisted content processing
    - Voice communication capabilities

    Provide efficient, organized communication solutions using Carbon Voice platform features.''',
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command='npx',
                    args=["-y", "@carbonvoice/cv-mcp-server"],
                    env={
                        # API key injected via header_provider in HTTP requests
                        "LOG_LEVEL": "info"
                    },
                ),
            ),
            header_provider=carbon_voice_header_provider
        )
    ],
)
