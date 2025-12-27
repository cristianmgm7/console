"""OAuth2 token exchange handler for GitHub and Carbon Voice."""

import requests
from typing import Dict, Any

from src.config import config


def exchange_code_for_token(provider: str, auth_code: str) -> Dict[str, Any]:
    """
    Exchange OAuth authorization code for access token.

    Args:
        provider: OAuth provider ('github' or 'carbon')
        auth_code: Authorization code from OAuth callback

    Returns:
        Dict with token data or error
    """
    if provider == "github":
        return exchange_github_token(auth_code)
    elif provider == "carbon":
        return exchange_carbon_token(auth_code)
    else:
        return {"error": f"Unknown provider: {provider}"}


def exchange_github_token(auth_code: str) -> Dict[str, Any]:
    """
    Exchange GitHub authorization code for access token.

    GitHub OAuth2 flow:
    1. User completes OAuth on GitHub
    2. GitHub redirects to callback with code
    3. We exchange code for access_token

    Args:
        auth_code: Authorization code from GitHub

    Returns:
        Dict with token, refresh_token, expiry
    """
    try:
        response = requests.post(
            config.GITHUB_TOKEN_URL,
            headers={
                "Accept": "application/json"
            },
            data={
                "client_id": config.GITHUB_CLIENT_ID,
                "client_secret": config.GITHUB_CLIENT_SECRET,
                "code": auth_code,
                "redirect_uri": config.GITHUB_REDIRECT_URI
            }
        )

        response.raise_for_status()
        token_data = response.json()

        if "error" in token_data:
            return {
                "error": token_data.get("error_description", "Token exchange failed")
            }

        # GitHub tokens format
        return {
            "token": token_data.get("access_token"),
            "refresh_token": token_data.get("refresh_token"),
            "token_type": token_data.get("token_type", "Bearer"),
            "scope": token_data.get("scope", "")
        }

    except Exception as e:
        return {"error": f"GitHub token exchange failed: {str(e)}"}


def exchange_carbon_token(auth_code: str) -> Dict[str, Any]:
    """
    Exchange Carbon Voice authorization code for access token.

    Args:
        auth_code: Authorization code from Carbon Voice

    Returns:
        Dict with token, refresh_token, expiry
    """
    try:
        response = requests.post(
            config.CARBON_TOKEN_URL,
            headers={
                "Content-Type": "application/x-www-form-urlencoded"
            },
            data={
                "grant_type": "authorization_code",
                "client_id": config.CARBON_CLIENT_ID,
                "client_secret": config.CARBON_CLIENT_SECRET,
                "code": auth_code,
                "redirect_uri": config.CARBON_REDIRECT_URI
            }
        )

        response.raise_for_status()
        token_data = response.json()

        if "error" in token_data:
            return {
                "error": token_data.get("error_description", "Token exchange failed")
            }

        # Carbon Voice tokens format
        return {
            "token": token_data.get("access_token"),
            "refresh_token": token_data.get("refresh_token"),
            "token_type": token_data.get("token_type", "Bearer"),
            "expires_in": token_data.get("expires_in"),
            "scope": token_data.get("scope", "")
        }

    except Exception as e:
        return {"error": f"Carbon Voice token exchange failed: {str(e)}"}
