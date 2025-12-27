"""GitHub agent with OAuth2 authentication using ADK native auth."""

from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPServerParams
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
import json

from src.config import config


# Token storage key in session state
GITHUB_TOKEN_KEY = "github_oauth_token"


def github_header_provider(readonly_context):
    """
    Header provider for GitHub MCP tools authentication.

    This function is called by ADK before each MCP tool request to inject
    authentication headers. It retrieves OAuth tokens from session state
    and automatically refreshes expired tokens.

    Args:
        readonly_context: ADK ReadonlyContext with session state access

    Returns:
        dict: HTTP headers including Authorization with GitHub token
    """
    session_state = readonly_context.session.state

    # Check for existing OAuth token in session
    cached_token_json = session_state.get(GITHUB_TOKEN_KEY)

    if cached_token_json:
        try:
            # Parse stored credentials
            token_data = json.loads(cached_token_json)
            creds = Credentials.from_authorized_user_info(
                token_data,
                scopes=config.GITHUB_SCOPES
            )

            # Automatic token refresh if expired
            if not creds.valid and creds.expired and creds.refresh_token:
                creds.refresh(Request())
                # Update session with refreshed token
                session_state[GITHUB_TOKEN_KEY] = creds.to_json()

            # Return Authorization header
            if creds.valid:
                return {
                    "Authorization": f"Bearer {creds.token}"
                }
        except Exception as e:
            # Log error but don't break - tool will fail with 401
            print(f"GitHub auth error: {e}")

    # No token available - MCP tool will fail with 401
    # Agent will need to handle authentication flow
    return {}


# Create GitHub agent
github_agent = Agent(
    model='gemini-2.5-flash',
    name='github_agent',
    description='A GitHub assistant powered by MCP tools for repository management, issues, and pull requests.',
    instruction='''You are a helpful GitHub assistant that can help users with:

    Repository Management:
    - Browse and query code files across repositories you have access to
    - Search files and analyze code patterns
    - Understand project structure and dependencies

    Issue & PR Management:
    - Create, update, and manage issues and pull requests
    - Help triage bugs and review code changes
    - Maintain project boards and track progress

    Code Analysis:
    - Examine security findings and Dependabot alerts
    - Analyze code patterns and provide insights
    - Review code changes and suggest improvements

    Always be helpful, accurate, and provide clear explanations of your actions.
    When using tools, explain what you're doing and why.''',
    tools=[
        McpToolset(
            connection_params=StreamableHTTPServerParams(
                url="https://api.githubcopilot.com/mcp/",
                headers={
                    # Static headers - auth token injected via header_provider
                    "X-MCP-Toolsets": "repos,issues,pull_requests,code_security,dependabot,discussions,projects,labels,notifications,users,orgs,stargazers",
                    "X-MCP-Readonly": "false"
                },
            ),
            header_provider=github_header_provider
        )
    ],
)
