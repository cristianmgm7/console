#!/usr/bin/env python3
"""Test script to verify ADK agent setup."""

import sys
import os

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))


def test_imports():
    """Test that all modules can be imported."""
    print("Testing imports...")

    try:
        from src.config import config
        print("✅ Config module imported")
    except Exception as e:
        print(f"❌ Config import failed: {e}")
        return False

    try:
        from src.agents import github_agent, carbon_voice_agent, root_agent
        print("✅ Agents imported")
    except Exception as e:
        print(f"❌ Agent import failed: {e}")
        return False

    try:
        from src.api import app, session_manager, AgentRunner
        print("✅ API modules imported")
    except Exception as e:
        print(f"❌ API import failed: {e}")
        return False

    return True


def test_configuration():
    """Test configuration loading."""
    print("\nTesting configuration...")

    try:
        from src.config import config

        # Check that config object exists
        assert hasattr(config, 'GOOGLE_API_KEY')
        assert hasattr(config, 'GITHUB_CLIENT_ID')
        assert hasattr(config, 'CARBON_CLIENT_ID')
        print("✅ Configuration attributes present")

        # Check for .env file
        env_file = os.path.join(os.path.dirname(__file__), '.env')
        if not os.path.exists(env_file):
            print("⚠️  Warning: .env file not found")
            print("   Run: cp .env.example .env")
            return False

        print("✅ .env file exists")

        # Try to validate (will fail if required vars missing)
        try:
            config.validate()
            print("✅ Configuration validated successfully")
            print(f"   - Google API Key: {'Set' if config.GOOGLE_API_KEY else 'Missing'}")
            print(f"   - Session Secret: {'Set' if config.SESSION_SECRET_KEY else 'Missing'}")
            print(f"   - GitHub Client ID: {'Set' if config.GITHUB_CLIENT_ID else 'Not set'}")
            print(f"   - Carbon Client ID: {'Set' if config.CARBON_CLIENT_ID else 'Not set'}")
            return True
        except ValueError as e:
            print(f"⚠️  Configuration incomplete: {e}")
            print("   Please fill in required values in .env file")
            return False

    except Exception as e:
        print(f"❌ Configuration test failed: {e}")
        return False


def test_agents():
    """Test agent initialization."""
    print("\nTesting agents...")

    try:
        from src.agents import github_agent, carbon_voice_agent, root_agent

        # Check agents are initialized
        assert github_agent is not None
        assert carbon_voice_agent is not None
        assert root_agent is not None
        print("✅ All agents initialized")

        # Check agent properties
        assert github_agent.name == 'github_agent'
        assert carbon_voice_agent.name == 'carbon_voice_agent'
        assert root_agent.name == 'root_orchestrator'
        print("✅ Agent names correct")

        # Check root agent has sub-agents
        assert len(root_agent.sub_agents) == 2
        print("✅ Root orchestrator has 2 sub-agents")

        return True

    except Exception as e:
        print(f"❌ Agent test failed: {e}")
        return False


def test_api():
    """Test FastAPI app setup."""
    print("\nTesting API setup...")

    try:
        from src.api import app

        # Check app is initialized
        assert app is not None
        print("✅ FastAPI app initialized")

        # Check routes exist
        routes = [route.path for route in app.routes]
        expected_routes = ['/chat/stream', '/oauth/callback/{provider}', '/session/{session_id}']

        for expected in expected_routes:
            # Check if route exists (may have different formats)
            found = any(expected.replace('{', '').replace('}', '') in route for route in routes)
            if found:
                print(f"✅ Route {expected} exists")
            else:
                print(f"⚠️  Route {expected} might be missing")

        return True

    except Exception as e:
        print(f"❌ API test failed: {e}")
        return False


def main():
    """Run all tests."""
    print("=" * 60)
    print("ADK Agent Setup Test")
    print("=" * 60)

    results = []

    results.append(("Imports", test_imports()))
    results.append(("Configuration", test_configuration()))
    results.append(("Agents", test_agents()))
    results.append(("API", test_api()))

    print("\n" + "=" * 60)
    print("Test Results")
    print("=" * 60)

    all_passed = True
    for name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{name:20} {status}")
        if not passed:
            all_passed = False

    print("=" * 60)

    if all_passed:
        print("\n🎉 All tests passed! Your setup is ready.")
        print("\nNext steps:")
        print("1. Ensure .env file has all required credentials")
        print("2. Run: python run.py")
        print("3. Test with: curl -X POST http://localhost:8000/chat/stream ...")
        return 0
    else:
        print("\n⚠️  Some tests failed. Please review the errors above.")
        print("\nCommon issues:")
        print("- Missing .env file: Run 'cp .env.example .env'")
        print("- Missing dependencies: Run 'pip install -r requirements.txt'")
        print("- Import errors: Check Python version (requires 3.10+)")
        return 1


if __name__ == "__main__":
    sys.exit(main())
