"""Configuration management for ADK agents."""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
env_path = Path(__file__).parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)


class Config:
    """Application configuration."""

    # Google ADK
    GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

    # GitHub OAuth2
    GITHUB_CLIENT_ID = os.getenv("GITHUB_CLIENT_ID")
    GITHUB_CLIENT_SECRET = os.getenv("GITHUB_CLIENT_SECRET")
    GITHUB_REDIRECT_URI = os.getenv("GITHUB_REDIRECT_URI", "http://localhost:8000/oauth/callback/github")
    GITHUB_AUTH_URL = "https://github.com/login/oauth/authorize"
    GITHUB_TOKEN_URL = "https://github.com/login/oauth/access_token"
    GITHUB_SCOPES = ["repo", "user", "read:org"]

    # Carbon Voice OAuth2
    CARBON_CLIENT_ID = os.getenv("CARBON_CLIENT_ID")
    CARBON_CLIENT_SECRET = os.getenv("CARBON_CLIENT_SECRET")
    CARBON_REDIRECT_URI = os.getenv("CARBON_REDIRECT_URI", "http://localhost:8000/oauth/callback/carbon")
    CARBON_AUTH_URL = "https://api.carbon.ai/oauth/authorize"
    CARBON_TOKEN_URL = "https://api.carbon.ai/oauth/token"
    CARBON_SCOPES = ["files:read", "files:write"]

    # FastAPI Server
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", "8000"))
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"

    # Session and Security
    SESSION_SECRET_KEY = os.getenv("SESSION_SECRET_KEY")
    TOKEN_ENCRYPTION_KEY = os.getenv("TOKEN_ENCRYPTION_KEY")

    @classmethod
    def validate(cls):
        """Validate that required configuration is present."""
        required = [
            ("GOOGLE_API_KEY", cls.GOOGLE_API_KEY),
            ("SESSION_SECRET_KEY", cls.SESSION_SECRET_KEY),
        ]

        missing = [name for name, value in required if not value]

        if missing:
            raise ValueError(
                f"Missing required environment variables: {', '.join(missing)}. "
                "Please copy .env.example to .env and fill in the values."
            )


config = Config()
