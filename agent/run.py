#!/usr/bin/env python3
"""
Run ADK agent server for Flutter consumption.

This script starts the ADK agent using the native `adk web` command,
which provides:
- Built-in web UI at /dev-ui/
- Agent execution endpoint at /run_sse
- Session management
- Proper MCP tool integration

For Flutter integration, the flow is:
1. Flutter handles OAuth (GitHub, Carbon Voice) natively
2. Flutter creates session with tokens via session init
3. Flutter sends chat requests to /run_sse with session_id
4. Agent executes with authenticated MCP tools
"""

import sys
import os
import subprocess

# Add src to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

if __name__ == "__main__":
    from src.config import config

    # Validate configuration
    try:
        config.validate()
    except ValueError as e:
        print(f"\n❌ Configuration Error: {e}\n")
        print("Please ensure you have:")
        print("1. Copied .env.example to .env")
        print("2. Filled in all required values (GOOGLE_API_KEY)\n")
        sys.exit(1)

    print("✅ Configuration validated successfully")
    print(f"🚀 Starting ADK Agent Server\n")

    # Run ADK web server
    # This uses ADK's native server which properly integrates:
    # - Session management
    # - MCP tools
    # - OAuth flow (for OpenAPI tools)
    # - Web UI for testing

    cmd = [
        "adk", "web", "src",
        "--host", config.HOST,
        "--port", str(config.PORT),
        "--session_service_uri", "sqlite:///.adk/session.db",
        "--reload" if config.DEBUG else "--no-reload",
    ]

    print("Running command:")
    print(" ".join(cmd))
    print()
    print("Available endpoints:")
    print(f"  - Web UI:     http://localhost:{config.PORT}/dev-ui/")
    print(f"  - Agent SSE:  POST http://localhost:{config.PORT}/run_sse")
    print(f"  - Sessions:   GET  http://localhost:{config.PORT}/apps/src/users/{{user_id}}/sessions")
    print()
    print("For Flutter integration:")
    print("  1. Flutter handles OAuth and gets tokens")
    print("  2. Use session_init.py to create session with tokens")
    print("  3. Flutter calls /run_sse with session_id")
    print()

    try:
        subprocess.run(cmd, check=True)
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error running ADK server: {e}")
        sys.exit(1)
