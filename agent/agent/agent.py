from google.adk.agents.llm_agent import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams, StdioServerParameters, StreamableHTTPServerParams
from google.adk.auth import AuthCredential, AuthCredentialTypes, OAuth2Auth
from fastapi.openapi.models import OAuth2, OAuthFlows, OAuthFlowAuthorizationCode
# from github_tools import github_tools  # Temporarily commented out
import json
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Load the manual OpenAPI specification
openapi_spec_path = Path(__file__).parent.parent / "openapi_spec.json"
if openapi_spec_path.exists():
    with open(openapi_spec_path, 'r') as f:
        OPENAPI_SPEC = json.load(f)
    print("Loaded manual OpenAPI specification")
else:
    OPENAPI_SPEC = {"error": "OpenAPI spec not found"}
    print("Warning: OpenAPI spec file not found")


def load_instruction(filename: str) -> str:
    """Load agent instruction from a text file."""
    instruction_path = Path(__file__).parent.parent / "instructions" / filename
    if instruction_path.exists():
        with open(instruction_path, 'r') as f:
            return f.read().strip()
    else:
        raise FileNotFoundError(f"Instruction file not found: {instruction_path}")




github_agent = Agent(
    model='gemini-2.5-flash',
    name='github_agent',
    description='A GitHub assistant that can manage repositories, issues, and pull requests with OAuth authentication.',
    instruction=load_instruction('github_agent.txt'),
    tools=[
        # Temporarily removed tools - will implement GitHub integration later
        # github_tools.list_user_repositories,
        # github_tools.get_repository_info,
    ],
)


# Create Carbon Voice agent
carbon_voice_agent = Agent(
    model='gemini-2.5-flash',
    name='carbon_voice_agent',
    description='A communication specialist for Carbon Voice messaging platform operations.',
    instruction=load_instruction('carbon_voice_agent.txt'),
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command='npx',
                    args=["-y", "@carbonvoice/cv-mcp-server"],
                    env={
                        "LOG_LEVEL": "info"
                    },
                ),
            ),
            auth_scheme=OAuth2(
                flows=OAuthFlows(
                    authorizationCode=OAuthFlowAuthorizationCode(
                        authorizationUrl="https://api.carbonvoice.app/oauth/authorize",
                        tokenUrl="https://api.carbonvoice.app/oauth/token",
                        scopes={
                            "files:read": "Read files",
                            "files:write": "Write files"
                        },
                    )
                )
            ),
            auth_credential=AuthCredential(
                auth_type=AuthCredentialTypes.OAUTH2,
                oauth2=OAuth2Auth(
                    client_id=os.getenv("CARBON_CLIENT_ID", "YOUR_CARBON_CLIENT_ID"),
                    client_secret=os.getenv("CARBON_CLIENT_SECRET", "YOUR_CARBON_CLIENT_SECRET"),
                    redirect_uri=os.getenv("CARBON_REDIRECT_URI", "https://cristianmgm7.github.io/carbon-console-auth/"),
                )
            )
        )
    ],
)

# Create Atlassian agent
atlassian_agent = Agent(
    model='gemini-2.5-flash',
    name='atlassian_agent',
    description='An Atlassian assistant powered by MCP tools for Jira, Confluence, and other Atlassian product operations.',
    instruction=load_instruction('atlassian_agent.txt'),
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://mcp.atlassian.com/v1/sse",
                    ]
                ),
                timeout=30,
            ),
        )
    ],
)

root_agent = Agent(
    model='gemini-2.5-flash',
    name='root_orchestrator',
    description='Main orchestrator agent that coordinates GitHub and Carbon Voice operations.',
    instruction=load_instruction('root_agent.txt'),
    sub_agents=[github_agent, carbon_voice_agent, atlassian_agent],
)
