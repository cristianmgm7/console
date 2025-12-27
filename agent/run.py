#!/usr/bin/env python3
"""Simple script to run the ADK agent server."""

import sys
import os

# Add src to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

if __name__ == "__main__":
    import uvicorn
    from src.config import config

    # Validate configuration
    try:
        config.validate()
    except ValueError as e:
        print(f"\n❌ Configuration Error: {e}\n")
        print("Please ensure you have:")
        print("1. Copied .env.example to .env")
        print("2. Filled in all required values (GOOGLE_API_KEY, SESSION_SECRET_KEY)\n")
        sys.exit(1)

    print("✅ Configuration validated successfully")
    print(f"🚀 Starting ADK Agent Server on {config.HOST}:{config.PORT}\n")
    print("Available endpoints:")
    print(f"  - POST http://localhost:{config.PORT}/chat/stream")
    print(f"  - GET  http://localhost:{config.PORT}/oauth/callback/github")
    print(f"  - GET  http://localhost:{config.PORT}/oauth/callback/carbon")
    print(f"  - GET  http://localhost:{config.PORT}/session/{{session_id}}")
    print()

    uvicorn.run(
        "src.api.main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.DEBUG,
        log_level="info"
    )
