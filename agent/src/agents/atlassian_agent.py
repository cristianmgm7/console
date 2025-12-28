"""Atlassian agent with OAuth2 authentication using ADK native auth."""

from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from mcp import StdioServerParameters

# Create Atlassian agent
atlassian_agent = Agent(
    model='gemini-2.5-flash',
    name='atlassian_agent',
    description='An Atlassian assistant powered by MCP tools for Jira, Confluence, and other Atlassian product operations.',
    instruction='''You are a helpful Atlassian assistant that can help users with:

    Jira Operations:
    - Create, update, and manage issues, tasks, and epics
    - Search and filter issues across projects
    - Manage project boards, sprints, and workflows
    - Handle issue transitions and status updates
    - Work with custom fields and issue types

    Confluence Operations:
    - Create and edit pages and blog posts
    - Search and navigate content across spaces
    - Manage spaces, permissions, and templates
    - Work with attachments and media
    - Handle page restrictions and comments

    Project Management:
    - Track project progress and metrics
    - Manage team assignments and workloads
    - Create and maintain project documentation
    - Coordinate between Jira and Confluence content
    - Generate reports and analytics

    Collaboration Features:
    - User and team management
    - Permission and access control
    - Integration with other Atlassian tools
    - Automation and workflow optimization

    Always be helpful, accurate, and provide clear explanations of your actions.
    When using tools, explain what you're doing and why. Maintain proper
    documentation and ensure all changes follow organizational standards.''',
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
