# MCP Credential Manager with Stytch OAuth Implementation Plan

## Overview

This plan describes how to build a **credential management backend** for an AI-driven multi-agent platform that uses MCP (Model Context Protocol) servers. The system consists of a Flutter client, a Python agent layer (Google ADK), and a new FastAPI backend server.

**Critical Design Principle**: Carbon Voice OAuth remains the **primary authentication method** for your app. The backend being built serves as a **credential vault and agent runtime**, not a replacement for your existing authentication.

### What This Backend Does

1. **Validates Carbon Voice tokens** - Accepts OAuth tokens from Flutter, validates with Carbon Voice API
2. **Issues session tokens** - Provides JWT tokens for backend API access
3. **Manages MCP credentials** - Stores OAuth tokens for GitHub, Google, Slack (via Stytch)
4. **Runs agents** - Embeds Google ADK runtime, injects user credentials into MCP tools
5. **Streams responses** - Returns agent output to Flutter via SSE

### What This Backend Does NOT Do

❌ Replace Carbon Voice login
❌ Create new user accounts (users exist in Carbon Voice)
❌ Manage user profiles (Carbon Voice owns user data)
❌ Handle password resets (Carbon Voice handles this)

## Current State Analysis

### Existing Components

**Flutter Client** ([carbon_voice_console/](file:///Users/cristian/Documents/tech/carbon_voice_console)):
- OAuth2 implementation authenticates to Carbon Voice API ([oauth_repository_impl.dart:1](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/features/auth/data/repositories/oauth_repository_impl.dart#L1))
- Stores Carbon Voice OAuth tokens in secure storage
- [AuthenticatedHttpService](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/core/network/authenticated_http_service.dart) uses these tokens for API calls
- Agent chat UI exists but uses mock data ([agent_chat_repository_impl.dart:13](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart#L13))
- **This authentication flow is CORRECT and will remain unchanged**

**Python Agent Layer** ([/agents/](file:///Users/cristian/Documents/tech/agents)):
- Multi-agent system using Google Agent Development Kit
- Root orchestrator coordinates sub-agents ([agent.py:37](file:///Users/cristian/Documents/tech/agents/carbon_agent/agent.py#L37))
- MCP integration via `McpToolset` with multiple transport types
- Currently stores API keys in `.env` files (needs to be dynamic per-user)
- No backend server - runs via `adk run` command

**Carbon Voice API** (`https://api.carbonvoice.app`):
- YOUR backend that owns user data
- OAuth2 provider that Flutter authenticates against
- REST API for messages, workspaces, users, etc.
- MCP server at `https://mcp.carbonvoice.app`

### Key Discoveries

1. **Carbon Voice auth is working** - Keep it!
2. **No agent-to-frontend connection** - Need to build backend API
3. **MCP credentials hardcoded** - Need per-user token storage
4. **No way to connect GitHub/Google** - Need OAuth broker via Stytch

### Authentication Gaps

1. No backend to validate Carbon Voice tokens and issue session tokens
2. No server-side storage for MCP credentials (GitHub, Google, Slack)
3. No way for agents to access user-specific credentials dynamically
4. No UI for users to connect external services

## Desired End State

After implementing this plan, the system will have:

1. **FastAPI Backend Server** hosting:
   - Carbon Voice token validation endpoint
   - JWT session token issuance
   - Stytch OAuth broker for MCP services (GitHub, Google, Slack)
   - Encrypted token storage in PostgreSQL
   - REST API for agent chat
   - SSE streaming for real-time agent responses
   - Embedded Google ADK agent runtime

2. **Carbon Voice Authentication Flow (UNCHANGED)**:
   - Users log in via Carbon Voice OAuth (existing Flutter flow)
   - Flutter sends Carbon Voice token to backend `/api/auth/validate`
   - Backend validates token with Carbon Voice API
   - Backend issues JWT session token for its own API
   - All subsequent backend requests use JWT

3. **MCP Credential Management (NEW)**:
   - Users click "Connect GitHub" in Flutter settings
   - Stytch OAuth flow handles GitHub authentication
   - Backend stores encrypted GitHub token in database
   - Agents can now access user's GitHub repos via MCP

4. **Structured Error Handling**:
   - Agent tries to use GitHub MCP tool
   - No GitHub token found for user
   - Backend returns `401` with `{provider: "github", auth_url: "..."}`
   - Flutter shows "Connect GitHub" prompt
   - After connection, agent request succeeds

5. **Real-time Agent Communication**:
   - Flutter sends message to `/api/agent/chat` with JWT
   - Backend loads user's Carbon Voice + GitHub + Google tokens
   - Backend invokes ADK agent with all credentials injected
   - Agent responses stream back via SSE

### Verification Criteria

**Automated Verification**:
- [ ] Backend server starts: `uvicorn main:app --reload`
- [ ] Database migrations run: `alembic upgrade head`
- [ ] Carbon Voice token validation works: `pytest tests/test_cv_auth.py`
- [ ] Stytch OAuth flows work: `pytest tests/test_stytch_oauth.py`
- [ ] Agent invocation with credentials works: `pytest tests/test_agent_service.py`

**Manual Verification**:
- [ ] User logs in via Carbon Voice (existing flow)
- [ ] Backend validates Carbon Voice token and issues JWT
- [ ] User can connect GitHub via Stytch
- [ ] User can connect Google via Stytch
- [ ] Agent chat uses user's credentials for MCP tools
- [ ] Missing credential triggers OAuth prompt in Flutter
- [ ] Logout clears backend session

## What We're NOT Doing

1. **Not replacing Carbon Voice OAuth** - It remains primary auth
2. **Not creating user accounts** - Users exist in Carbon Voice
3. **Not storing user profiles** - Carbon Voice is source of truth
4. **Not implementing email/password login** - Carbon Voice handles this
5. **Not using Stytch for user identity** - Only for MCP OAuth
6. **Not building user management UI** - Just credential connections
7. **Not migrating existing users** - They already have Carbon Voice accounts
8. **Not implementing RBAC** - Carbon Voice permissions apply
9. **Not supporting offline mode** - Requires active internet
10. **Not building separate admin panel** - API-only

## Implementation Approach

We will build this in phases:

1. **Phase 1**: Backend infrastructure (FastAPI, PostgreSQL, database models)
2. **Phase 2**: Carbon Voice token validation and JWT session management
3. **Phase 3**: Stytch OAuth integration for MCP credentials (GitHub, Google, Slack)
4. **Phase 4**: Agent runtime with credential injection
5. **Phase 5**: Flutter integration (SSE client, OAuth UI)

---

## Phase 1: Backend Infrastructure Setup

### Overview
Set up FastAPI backend with PostgreSQL database. Create models for users (synced from Carbon Voice) and MCP OAuth tokens.

### Changes Required

#### 1. Backend Project Structure

**Directory**: `/Users/cristian/Documents/tech/agents/backend/`

```
backend/
├── main.py
├── requirements.txt
├── alembic.ini
├── .env.example
├── .env
├── app/
│   ├── __init__.py
│   ├── config.py
│   ├── database.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py              # Synced from Carbon Voice
│   │   └── mcp_token.py         # MCP OAuth tokens
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   └── agent.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py
│   │   ├── auth.py              # Carbon Voice validation
│   │   ├── mcp_oauth.py         # Stytch OAuth
│   │   └── agent.py             # Agent chat
│   ├── services/
│   │   ├── __init__.py
│   │   ├── carbon_voice_auth.py # Validates CV tokens
│   │   ├── stytch_oauth.py      # Stytch OAuth flows
│   │   └── agent_service.py     # ADK runtime
│   └── core/
│       ├── __init__.py
│       ├── security.py          # JWT utilities
│       └── encryption.py        # Token encryption
├── alembic/
│   ├── env.py
│   └── versions/
└── tests/
    ├── __init__.py
    └── test_cv_auth.py
```

**File**: `backend/requirements.txt`

```txt
# FastAPI and server
fastapi==0.109.0
uvicorn[standard]==0.27.0
python-multipart==0.0.6
sse-starlette==1.8.2

# Database
sqlalchemy==2.0.25
alembic==1.13.1
psycopg2-binary==2.9.9
asyncpg==0.29.0

# Authentication
stytch==6.0.0
python-jose[cryptography]==3.3.0
python-dotenv==1.0.0

# Encryption
cryptography==42.0.0

# Google ADK
google-adk==1.21.0
google-genai==1.56.0

# HTTP client
httpx==0.28.1

# Utilities
pydantic==2.5.3
pydantic-settings==2.1.0

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
```

**File**: `backend/.env.example`

```bash
# Application
ENVIRONMENT=development
DEBUG=True
SECRET_KEY=your-secret-key-generate-with-openssl-rand-hex-32

# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/carbon_agent_db

# Carbon Voice API (for token validation)
CARBON_VOICE_API_URL=https://api.carbonvoice.app
CARBON_VOICE_MCP_URL=https://mcp.carbonvoice.app

# Stytch (for MCP OAuth only)
STYTCH_PROJECT_ID=project-test-xxx
STYTCH_SECRET=secret-test-xxx
STYTCH_ENVIRONMENT=test

# OAuth Encryption Key
OAUTH_ENCRYPTION_KEY=generate-with-fernet-generate-key

# Frontend
CORS_ORIGINS=http://localhost:3000,https://carbonconsole.ngrok.app

# JWT
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=1440  # 24 hours
```

**File**: `backend/app/config.py`

```python
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Application
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str

    # Database
    DATABASE_URL: str

    # Carbon Voice
    CARBON_VOICE_API_URL: str
    CARBON_VOICE_MCP_URL: str

    # Stytch (for MCP OAuth only)
    STYTCH_PROJECT_ID: str
    STYTCH_SECRET: str
    STYTCH_ENVIRONMENT: str = "test"

    # Encryption
    OAUTH_ENCRYPTION_KEY: str

    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000"]

    # JWT
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_MINUTES: int = 1440

    class Config:
        env_file = ".env"

settings = Settings()
```

**File**: `backend/app/database.py`

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()

async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session
```

#### 2. Database Models

**File**: `backend/app/models/user.py`

```python
from sqlalchemy import Column, String, DateTime, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
from app.database import Base

class User(Base):
    """
    User model synced from Carbon Voice.
    We don't create users - they exist in Carbon Voice.
    We just cache their info for relational integrity with MCP tokens.
    """
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Carbon Voice user ID (from their API)
    carbon_voice_user_id = Column(String, unique=True, nullable=False, index=True)

    # User info from Carbon Voice
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Soft delete (if user deleted in Carbon Voice)
    is_active = Column(Boolean, default=True)
```

**File**: `backend/app/models/mcp_token.py`

```python
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
from app.database import Base

class McpToken(Base):
    """
    OAuth tokens for MCP services (GitHub, Google, Slack).
    Obtained via Stytch OAuth flows.
    """
    __tablename__ = "mcp_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Provider: "github", "google", "slack"
    provider = Column(String, nullable=False, index=True)

    # Encrypted OAuth tokens
    access_token_encrypted = Column(Text, nullable=False)
    refresh_token_encrypted = Column(Text, nullable=True)

    # Token metadata
    expires_at = Column(DateTime(timezone=True), nullable=True)
    scope = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationship
    user = relationship("User", backref="mcp_tokens")

    # One token per user per provider
    __table_args__ = (
        UniqueConstraint('user_id', 'provider', name='uq_user_provider'),
    )
```

#### 3. Encryption Utility

**File**: `backend/app/core/encryption.py`

```python
from cryptography.fernet import Fernet
from app.config import settings

fernet = Fernet(settings.OAUTH_ENCRYPTION_KEY.encode())

def encrypt_token(token: str) -> str:
    """Encrypt OAuth token for database storage"""
    return fernet.encrypt(token.encode()).decode()

def decrypt_token(encrypted_token: str) -> str:
    """Decrypt OAuth token from database"""
    return fernet.decrypt(encrypted_token.encode()).decode()
```

#### 4. FastAPI Application

**File**: `backend/main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app = FastAPI(
    title="Carbon Voice Agent Backend",
    description="Credential manager and agent runtime for Carbon Voice",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    await create_tables()

@app.get("/")
async def root():
    return {"status": "ok", "service": "carbon-voice-agent-backend"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

#### 5. Alembic Setup

Generate encryption key first:
```python
from cryptography.fernet import Fernet
print(Fernet.generate_key().decode())
```

Initialize Alembic:
```bash
cd backend
alembic init alembic
```

Update `alembic/env.py` similar to previous plan (import models, set URL from config).

Create initial migration:
```bash
alembic revision --autogenerate -m "Initial: users and mcp_tokens tables"
alembic upgrade head
```

### Success Criteria

#### Automated Verification:
- [ ] Dependencies install: `pip install -r backend/requirements.txt`
- [ ] PostgreSQL running and accessible
- [ ] Environment variables load: `python -c "from app.config import settings; print(settings.DATABASE_URL)"`
- [ ] Migrations generate: `alembic revision --autogenerate -m "test"`
- [ ] Migrations apply: `alembic upgrade head`
- [ ] Server starts: `uvicorn main:app --reload`
- [ ] Health check: `curl http://localhost:8000/health` returns 200

#### Manual Verification:
- [ ] Database tables created (users, mcp_tokens)
- [ ] `.env` configured correctly
- [ ] Alembic version table exists
- [ ] API docs accessible at `http://localhost:8000/docs`

**Implementation Note**: After verification, proceed to Phase 2.

---

## Phase 2: Carbon Voice Token Validation

### Overview
Implement endpoint to validate Carbon Voice OAuth tokens and issue JWT session tokens for backend API access.

### Changes Required

#### 1. JWT Security Utilities

**File**: `backend/app/core/security.py`

```python
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from app.config import settings
import uuid

def create_jwt_token(user_id: uuid.UUID, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT session token for backend API access"""
    to_encode = {"sub": str(user_id)}

    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.JWT_EXPIRATION_MINUTES)

    to_encode.update({"exp": expire, "iat": datetime.utcnow()})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

def verify_jwt_token(token: str) -> uuid.UUID:
    """Verify JWT and return user ID"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id_str = payload.get("sub")
        if not user_id_str:
            raise ValueError("Invalid token")
        return uuid.UUID(user_id_str)
    except JWTError:
        raise ValueError("Invalid or expired token")
```

#### 2. Carbon Voice Auth Service

**File**: `backend/app/services/carbon_voice_auth.py`

```python
import httpx
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.user import User
from app.config import settings
import uuid

class CarbonVoiceAuthService:
    """Validates Carbon Voice OAuth tokens and syncs user data"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def validate_token_and_get_user(self, carbon_voice_token: str) -> User:
        """
        Validate Carbon Voice OAuth token and return/create user.

        Args:
            carbon_voice_token: OAuth token from Carbon Voice

        Returns:
            User object

        Raises:
            ValueError: If token is invalid
        """
        # Call Carbon Voice API to validate token and get user info
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{settings.CARBON_VOICE_API_URL}/api/users/me",
                headers={"Authorization": f"Bearer {carbon_voice_token}"},
            )

            if response.status_code != 200:
                raise ValueError("Invalid Carbon Voice token")

            user_data = response.json()

        # Get or create user in our database
        carbon_voice_user_id = user_data["id"]

        result = await self.db.execute(
            select(User).where(User.carbon_voice_user_id == carbon_voice_user_id)
        )
        user = result.scalars().first()

        if user:
            # Update user info if changed
            user.email = user_data.get("email", user.email)
            user.name = user_data.get("name", user.name)
            user.is_active = True
            await self.db.commit()
            await self.db.refresh(user)
        else:
            # Create new user
            user = User(
                id=uuid.uuid4(),
                carbon_voice_user_id=carbon_voice_user_id,
                email=user_data.get("email"),
                name=user_data.get("name"),
            )
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)

        return user
```

#### 3. API Dependencies

**File**: `backend/app/api/deps.py`

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.core.security import verify_jwt_token
from app.models.user import User
from sqlalchemy.future import select

security = HTTPBearer()

async def get_current_user(
    credentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Get current user from JWT token"""
    token = credentials.credentials

    try:
        user_id = verify_jwt_token(token)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )

    return user
```

#### 4. Auth Endpoints

**File**: `backend/app/schemas/auth.py`

```python
from pydantic import BaseModel
from datetime import datetime

class ValidateTokenRequest(BaseModel):
    carbon_voice_token: str

class SessionTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: "UserInfo"

class UserInfo(BaseModel):
    id: str
    email: str
    name: str | None

    class Config:
        from_attributes = True
```

**File**: `backend/app/api/auth.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.carbon_voice_auth import CarbonVoiceAuthService
from app.schemas.auth import ValidateTokenRequest, SessionTokenResponse, UserInfo
from app.core.security import create_jwt_token
from app.config import settings
from datetime import timedelta

router = APIRouter()

@router.post("/validate", response_model=SessionTokenResponse)
async def validate_carbon_voice_token(
    request: ValidateTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Validate Carbon Voice OAuth token and issue backend session token.

    Flow:
    1. Flutter sends Carbon Voice OAuth token
    2. Backend validates with Carbon Voice API
    3. Backend returns JWT for subsequent requests
    """
    auth_service = CarbonVoiceAuthService(db)

    try:
        user = await auth_service.validate_token_and_get_user(request.carbon_voice_token)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )

    # Issue JWT session token
    jwt_token = create_jwt_token(
        user_id=user.id,
        expires_delta=timedelta(minutes=settings.JWT_EXPIRATION_MINUTES),
    )

    return SessionTokenResponse(
        access_token=jwt_token,
        expires_in=settings.JWT_EXPIRATION_MINUTES * 60,
        user=UserInfo(
            id=str(user.id),
            email=user.email,
            name=user.name,
        ),
    )
```

Update `main.py`:
```python
from app.api import auth

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
```

### Success Criteria

#### Automated Verification:
- [ ] Token validation with valid Carbon Voice token creates user: `pytest tests/test_cv_auth.py::test_validate_token`
- [ ] Invalid token returns 401: `pytest tests/test_cv_auth.py::test_invalid_token`
- [ ] JWT token returned and verified: `pytest tests/test_cv_auth.py::test_jwt_token`
- [ ] User synced to database: `pytest tests/test_cv_auth.py::test_user_sync`

#### Manual Verification:
- [ ] Get Carbon Voice token from existing Flutter app
- [ ] Call `/api/auth/validate` with token via Postman
- [ ] Receive JWT in response
- [ ] Verify user created in PostgreSQL
- [ ] Use JWT for protected endpoints

**Implementation Note**: Proceed to Phase 3 after verification.

---

## Phase 3: Stytch OAuth for MCP Credentials

### Overview
Implement Stytch OAuth flows for connecting GitHub, Google, Slack. Store encrypted tokens in database.

### Changes Required

#### 1. Stytch OAuth Service

**File**: `backend/app/services/stytch_oauth.py`

```python
import stytch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.mcp_token import McpToken
from app.core.encryption import encrypt_token, decrypt_token
from app.config import settings
from datetime import datetime, timedelta
from typing import Optional
import uuid

# Initialize Stytch client
stytch_client = stytch.Client(
    project_id=settings.STYTCH_PROJECT_ID,
    secret=settings.STYTCH_SECRET,
    environment=settings.STYTCH_ENVIRONMENT,
)

class StytchOAuthService:
    """Handles OAuth flows for MCP providers via Stytch"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def start_oauth_flow(
        self,
        provider: str,  # "github", "google", "slack"
        redirect_url: str,
    ) -> str:
        """
        Start Stytch OAuth flow for a provider.

        Returns:
            OAuth authorization URL to redirect user to
        """
        # Use Stytch OAuth connections
        # Each provider has specific setup in Stytch dashboard

        if provider == "github":
            oauth_url = stytch_client.oauth.github.start(
                signup_redirect_url=redirect_url,
                login_redirect_url=redirect_url,
            )
        elif provider == "google":
            oauth_url = stytch_client.oauth.google.start(
                signup_redirect_url=redirect_url,
                login_redirect_url=redirect_url,
            )
        # Add more providers as needed

        return oauth_url

    async def handle_oauth_callback(
        self,
        provider: str,
        token: str,  # Stytch OAuth token from callback
        user_id: uuid.UUID,
    ) -> McpToken:
        """
        Handle OAuth callback and store tokens.

        Args:
            provider: "github", "google", etc.
            token: Stytch OAuth token from callback
            user_id: Our user ID

        Returns:
            McpToken object
        """
        # Authenticate OAuth token with Stytch
        if provider == "github":
            auth_response = stytch_client.oauth.github.authenticate(token=token)
        elif provider == "google":
            auth_response = stytch_client.oauth.google.authenticate(token=token)

        # Extract provider access token from Stytch response
        provider_access_token = auth_response.provider_values.access_token
        provider_refresh_token = getattr(auth_response.provider_values, 'refresh_token', None)
        expires_in = getattr(auth_response.provider_values, 'expires_in', None)

        # Calculate expiration
        expires_at = None
        if expires_in:
            expires_at = datetime.utcnow() + timedelta(seconds=expires_in)

        # Encrypt tokens
        access_token_encrypted = encrypt_token(provider_access_token)
        refresh_token_encrypted = None
        if provider_refresh_token:
            refresh_token_encrypted = encrypt_token(provider_refresh_token)

        # Check if token exists
        result = await self.db.execute(
            select(McpToken).where(
                McpToken.user_id == user_id,
                McpToken.provider == provider,
            )
        )
        existing_token = result.scalars().first()

        if existing_token:
            # Update
            existing_token.access_token_encrypted = access_token_encrypted
            existing_token.refresh_token_encrypted = refresh_token_encrypted
            existing_token.expires_at = expires_at
            existing_token.updated_at = datetime.utcnow()
            await self.db.commit()
            await self.db.refresh(existing_token)
            return existing_token
        else:
            # Create
            mcp_token = McpToken(
                id=uuid.uuid4(),
                user_id=user_id,
                provider=provider,
                access_token_encrypted=access_token_encrypted,
                refresh_token_encrypted=refresh_token_encrypted,
                expires_at=expires_at,
            )
            self.db.add(mcp_token)
            await self.db.commit()
            await self.db.refresh(mcp_token)
            return mcp_token

    async def get_token(
        self,
        user_id: uuid.UUID,
        provider: str,
    ) -> Optional[str]:
        """Get decrypted token for user and provider"""
        result = await self.db.execute(
            select(McpToken).where(
                McpToken.user_id == user_id,
                McpToken.provider == provider,
            )
        )
        mcp_token = result.scalars().first()

        if not mcp_token:
            return None

        # Check expiration
        if mcp_token.expires_at and mcp_token.expires_at < datetime.utcnow():
            # TODO: Implement token refresh
            return None

        return decrypt_token(mcp_token.access_token_encrypted)

    async def disconnect_provider(
        self,
        user_id: uuid.UUID,
        provider: str,
    ) -> bool:
        """Delete MCP token"""
        result = await self.db.execute(
            select(McpToken).where(
                McpToken.user_id == user_id,
                McpToken.provider == provider,
            )
        )
        mcp_token = result.scalars().first()

        if mcp_token:
            await self.db.delete(mcp_token)
            await self.db.commit()
            return True

        return False
```

#### 2. MCP OAuth Endpoints

**File**: `backend/app/schemas/mcp.py`

```python
from pydantic import BaseModel
from datetime import datetime

class StartOAuthRequest(BaseModel):
    provider: str
    redirect_url: str

class OAuthCallbackRequest(BaseModel):
    provider: str
    token: str  # Stytch OAuth token

class ConnectedProvider(BaseModel):
    provider: str
    connected_at: datetime
    expires_at: datetime | None
```

**File**: `backend/app/api/mcp_oauth.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.api.deps import get_current_user
from app.services.stytch_oauth import StytchOAuthService
from app.schemas.mcp import StartOAuthRequest, OAuthCallbackRequest, ConnectedProvider
from app.models.user import User

router = APIRouter()

@router.post("/start")
async def start_mcp_oauth(
    request: StartOAuthRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Start OAuth flow for MCP provider (GitHub, Google, Slack)"""
    oauth_service = StytchOAuthService(db)

    try:
        auth_url = await oauth_service.start_oauth_flow(
            provider=request.provider,
            redirect_url=request.redirect_url,
        )
        return {"authorization_url": auth_url}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to start OAuth: {str(e)}",
        )

@router.post("/callback")
async def mcp_oauth_callback(
    request: OAuthCallbackRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Handle OAuth callback from Stytch"""
    oauth_service = StytchOAuthService(db)

    try:
        mcp_token = await oauth_service.handle_oauth_callback(
            provider=request.provider,
            token=request.token,
            user_id=current_user.id,
        )
        return {
            "success": True,
            "provider": mcp_token.provider,
            "message": f"Successfully connected {request.provider}",
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"OAuth callback failed: {str(e)}",
        )

@router.delete("/{provider}")
async def disconnect_mcp_provider(
    provider: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Disconnect MCP provider"""
    oauth_service = StytchOAuthService(db)

    success = await oauth_service.disconnect_provider(
        user_id=current_user.id,
        provider=provider,
    )

    if success:
        return {"success": True, "message": f"Disconnected {provider}"}
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No connection found for {provider}",
        )

@router.get("/connections")
async def get_mcp_connections(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List connected MCP providers"""
    from sqlalchemy.future import select
    from app.models.mcp_token import McpToken

    result = await db.execute(
        select(McpToken).where(McpToken.user_id == current_user.id)
    )
    tokens = result.scalars().all()

    return {
        "connections": [
            ConnectedProvider(
                provider=token.provider,
                connected_at=token.created_at,
                expires_at=token.expires_at,
            )
            for token in tokens
        ]
    }
```

Update `main.py`:
```python
from app.api import auth, mcp_oauth

app.include_router(mcp_oauth.router, prefix="/api/mcp", tags=["mcp-oauth"])
```

### Success Criteria

#### Automated Verification:
- [ ] OAuth flow starts: `pytest tests/test_stytch_oauth.py::test_start_flow`
- [ ] Callback stores token: `pytest tests/test_stytch_oauth.py::test_callback`
- [ ] Token encryption works: `pytest tests/test_encryption.py`
- [ ] Get token returns decrypted: `pytest tests/test_stytch_oauth.py::test_get_token`
- [ ] Disconnect removes token: `pytest tests/test_stytch_oauth.py::test_disconnect`

#### Manual Verification:
- [ ] Configure GitHub OAuth in Stytch dashboard
- [ ] Call `/api/mcp/start` for GitHub
- [ ] Complete OAuth flow in browser
- [ ] Call `/api/mcp/callback` with Stytch token
- [ ] Verify token stored encrypted in database
- [ ] Call `/api/mcp/connections` to see GitHub listed
- [ ] Disconnect GitHub

**Implementation Note**: Proceed to Phase 4 after verification.

---

_(Phase 4 and 5 would follow similar structure focusing on agent runtime and Flutter integration, maintaining the same level of detail. Would you like me to continue with those phases?)_

## References

- **Carbon Voice API Documentation**: https://api.carbonvoice.app/docs
- **Stytch OAuth Documentation**: https://stytch.com/docs/guides/oauth/overview
- **Google ADK Documentation**: https://github.com/googleapis/agent-development-kit
- **FastAPI**: https://fastapi.tiangelo.com
- **SQLAlchemy Async**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                           │
│                                                                  │
│  1. User logs in via Carbon Voice OAuth (UNCHANGED)             │
│  2. Flutter gets Carbon Voice token                             │
│  3. Flutter calls /api/auth/validate with CV token              │
│  4. Backend validates and returns JWT                           │
│  5. Flutter uses JWT for all backend requests                   │
│                                                                  │
│  When user clicks "Connect GitHub":                             │
│  6. Flutter calls /api/mcp/start → gets Stytch OAuth URL        │
│  7. User completes OAuth in browser                             │
│  8. Flutter calls /api/mcp/callback with Stytch token           │
│  9. Backend stores encrypted GitHub token                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ JWT Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                             │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  /api/auth/validate  - Validate CV token, issue JWT   │    │
│  │  /api/mcp/start      - Start Stytch OAuth for provider│    │
│  │  /api/mcp/callback   - Store MCP tokens               │    │
│  │  /api/agent/chat     - Agent with user credentials    │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ CV Auth Svc  │  │ Stytch OAuth │  │ Agent Service│          │
│  │ (validates)  │  │ (MCP tokens) │  │ (ADK Runtime)│          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         ▼                 ▼                 │                   │
│  ┌─────────────────────────────────┐       │                   │
│  │      PostgreSQL Database        │       │                   │
│  │  ┌─────────┐  ┌───────────────┐│       │                   │
│  │  │ users   │  │  mcp_tokens   ││       │                   │
│  │  │(from CV)│  │  (encrypted)  ││       │                   │
│  │  └─────────┘  └───────────────┘│       │                   │
│  └─────────────────────────────────┘       │                   │
│                                             │                   │
│  ┌──────────────────────────────────────┐  │                   │
│  │      Google ADK Agent Runtime        │◄─┘                   │
│  │  Gets user's MCP tokens dynamically  │                      │
│  └──────────────────────────────────────┘                      │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       │ MCP with user credentials
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              External Services (via MCP)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ GitHub       │  │ Google Drive │  │ Carbon Voice │          │
│  │ (user's token)  │ (user's token)  │ (MCP server) │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```
