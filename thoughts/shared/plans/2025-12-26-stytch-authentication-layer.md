# Stytch-Based Authentication Layer Implementation Plan

## Overview

This plan describes how to build a centralized authentication and OAuth credential management system for an AI-driven multi-agent platform. The system consists of a Flutter client, a Python agent layer (Google ADK), and a new FastAPI backend server that will act as the single source of truth for user identity, session management, and MCP (Model Context Protocol) server credentials.

The authentication layer uses Stytch for user identity management and acts as an OAuth broker for third-party integrations (Google, GitHub, Slack) that agents need to access via MCP servers. The design ensures agents remain authentication-agnostic, the frontend remains free of secrets, and users have a seamless experience when connecting external services.

## Current State Analysis

### Existing Components

**Flutter Client** ([carbon_voice_console/](file:///Users/cristian/Documents/tech/carbon_voice_console)):
- Clean architecture with BLoC pattern for state management
- OAuth2 implementation using `oauth2` package ([oauth_repository_impl.dart:1](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/features/auth/data/repositories/oauth_repository_impl.dart#L1))
- Authenticates directly to Carbon Voice API (`https://api.carbonvoice.app`)
- Stores credentials in browser/secure storage via [oauth_local_datasource.dart](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/features/auth/data/datasources/oauth_local_datasource.dart)
- Agent chat UI exists but uses **mock data only** ([agent_chat_repository_impl.dart:13](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart#L13))
- [AuthenticatedHttpService](file:///Users/cristian/Documents/tech/carbon_voice_console/lib/core/network/authenticated_http_service.dart) handles authenticated HTTP calls

**Python Agent Layer** ([/agents/](file:///Users/cristian/Documents/tech/agents)):
- Multi-agent system using Google Agent Development Kit (ADK)
- Root orchestrator agent coordinates specialized sub-agents ([agent.py:37](file:///Users/cristian/Documents/tech/agents/carbon_agent/agent.py#L37))
- Sub-agents: `github_agent`, `market_analyzer`, `carbon_voice_agent`
- MCP integration via `McpToolset` with multiple transport types (Stdio, SSE, HTTP)
- Manual OAuth flow via `oauth_helper.py` (standalone script on port 3000)
- Stores API keys and tokens in `.env` files
- **No backend server** - runs via `adk run` command

**Backend Server**:
- **Does NOT exist yet** - needs to be built from scratch
- Will be a FastAPI application hosting both auth endpoints and agent runtime

### Key Discoveries

1. **Two separate OAuth configurations**: Flutter and agents use different client IDs/secrets for Carbon Voice
2. **No agent-to-frontend connection**: Agent chat in Flutter is completely mocked
3. **Fragmented credential storage**: Flutter stores OAuth tokens locally, agents store in `.env` files
4. **No centralized auth service**: Each component authenticates independently
5. **No Stytch integration**: Current system uses Carbon Voice's OAuth provider only

### Authentication Gaps

1. No unified user identity system
2. No secure server-side token storage for MCP credentials
3. No way for agents to access user-specific OAuth tokens
4. No structured error handling for missing/expired credentials
5. No mechanism for Flutter to trigger OAuth flows for MCP services

## Desired End State

After implementing this plan, the system will have:

1. **FastAPI Backend Server** hosting:
   - Stytch-based user authentication endpoints
   - OAuth broker for MCP service integrations (Google, GitHub, Slack)
   - Token storage and refresh management in PostgreSQL
   - REST API for agent chat communication
   - SSE streaming for real-time agent responses
   - Embedded Google ADK agent runtime

2. **Unified Authentication Flow**:
   - Users log in via Stytch (email, Google, GitHub social login)
   - Backend issues JWT session tokens to Flutter client
   - All subsequent requests authenticated via JWT
   - User records synced to local PostgreSQL database

3. **MCP Credential Management**:
   - Per-user OAuth tokens for MCP services stored encrypted in database
   - Backend exposes clean credential access API for agent layer
   - Agents request credentials at runtime without knowing OAuth details
   - Automatic token refresh handling

4. **Structured Error Handling**:
   - Agents detect missing credentials and throw specific exceptions
   - Backend catches these and returns structured `401` responses with provider info
   - Flutter receives missing credential signals and prompts user to connect service
   - After OAuth completion, Flutter retries original agent request

5. **Real-time Agent Communication**:
   - Flutter sends messages to `/api/agent/chat` endpoint
   - Backend validates JWT, loads user's MCP credentials
   - Backend invokes Google ADK agents with user context
   - Agent responses streamed back via SSE
   - Messages persisted in PostgreSQL

### Verification Criteria

**Automated Verification**:
- [ ] Backend server starts successfully: `uvicorn main:app --reload`
- [ ] Database migrations run cleanly: `alembic upgrade head`
- [ ] All backend tests pass: `pytest tests/`
- [ ] Flutter app compiles: `flutter build web`
- [ ] Integration tests pass for auth flows: `pytest tests/integration/test_auth_flow.py`

**Manual Verification**:
- [ ] User can register via Stytch email/password
- [ ] User can log in via Stytch Google social login
- [ ] JWT tokens are issued and stored in Flutter
- [ ] Protected routes require valid JWT
- [ ] Agent chat sends messages and receives SSE responses
- [ ] When agent needs GitHub access, Flutter shows "Connect GitHub" prompt
- [ ] After OAuth connection, agent successfully uses GitHub MCP tools
- [ ] Tokens refresh automatically without user intervention
- [ ] User can disconnect external services from settings
- [ ] Logout clears all tokens and sessions

## What We're NOT Doing

1. **Not using Stytch OAuth Connections feature** - We're managing OAuth flows ourselves for maximum flexibility
2. **Not migrating existing Carbon Voice OAuth** - We're replacing it entirely with Stytch for user identity
3. **Not supporting passwordless SMS** - Email and social login only for MVP
4. **Not implementing MFA** - Basic auth first, can add later
5. **Not building admin dashboard** - API-only for now
6. **Not handling billing/subscriptions** - Authentication only
7. **Not supporting offline mode** - Requires active internet connection
8. **Not implementing RBAC** - Simple user-level permissions only
9. **Not building WebSocket support** - SSE is sufficient for one-way streaming
10. **Not supporting multiple workspaces** - Single workspace per user for MVP

## Implementation Approach

We will build this system in phases, starting with backend infrastructure, then authentication, then MCP credential management, and finally Flutter integration. Each phase will be independently testable and deployable.

The backend will be a FastAPI application using:
- **Stytch Python SDK** for user authentication
- **SQLAlchemy + Alembic** for database ORM and migrations
- **PostgreSQL** for persistent storage with encrypted token columns
- **Google ADK** embedded for agent runtime
- **SSE-starlette** for streaming agent responses
- **JWT (via python-jose)** for session tokens

The Flutter client will be updated to:
- Replace Carbon Voice OAuth with Stytch authentication
- Add JWT token management
- Implement SSE client for agent chat
- Add OAuth connection UI for MCP services
- Handle structured credential error responses

---

## Phase 1: Backend Infrastructure Setup

### Overview
Set up the FastAPI backend server with database, migrations, and basic project structure. This establishes the foundation for all subsequent phases.

### Changes Required

#### 1. Backend Project Initialization
**Directory**: `/Users/cristian/Documents/tech/agents/backend/`

Create new FastAPI project structure:

```
backend/
├── main.py                  # FastAPI app entry point
├── requirements.txt         # Python dependencies
├── alembic.ini             # Database migration config
├── .env.example            # Environment variable template
├── .env                    # Local environment (gitignored)
├── app/
│   ├── __init__.py
│   ├── config.py           # Configuration management
│   ├── database.py         # Database connection
│   ├── models/             # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── oauth_token.py
│   ├── schemas/            # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   └── agent.py
│   ├── api/                # API routes
│   │   ├── __init__.py
│   │   ├── deps.py         # Dependencies
│   │   ├── auth.py         # Auth endpoints
│   │   └── agent.py        # Agent chat endpoints
│   ├── services/           # Business logic
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── oauth_service.py
│   │   └── agent_service.py
│   └── core/               # Core utilities
│       ├── __init__.py
│       ├── security.py     # JWT utilities
│       └── encryption.py   # Token encryption
├── alembic/                # Database migrations
│   ├── env.py
│   └── versions/
└── tests/                  # Test suite
    ├── __init__.py
    ├── conftest.py
    └── test_auth.py
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
passlib[bcrypt]==1.7.4
python-dotenv==1.0.0

# Google ADK (existing dependency)
google-adk==1.21.0
google-genai==1.56.0

# Encryption
cryptography==42.0.0

# Utilities
pydantic==2.5.3
pydantic-settings==2.1.0
httpx==0.28.1

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-cov==4.1.0
```

**File**: `backend/.env.example`

```bash
# Application
ENVIRONMENT=development
DEBUG=True
SECRET_KEY=your-secret-key-here-generate-with-openssl-rand-hex-32

# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/carbon_voice_db

# Stytch
STYTCH_PROJECT_ID=project-test-xxx
STYTCH_SECRET=secret-test-xxx
STYTCH_ENVIRONMENT=test  # or 'live' for production

# OAuth Encryption Key (for MCP tokens)
OAUTH_ENCRYPTION_KEY=generate-with-fernet-key

# Carbon Voice API (for MCP server)
CARBON_VOICE_MCP_URL=https://mcp.carbonvoice.app

# Frontend
CORS_ORIGINS=http://localhost:3000,https://carbonconsole.ngrok.app
```

**File**: `backend/main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base
from app.api import auth, agent

# Create database tables
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app = FastAPI(
    title="Carbon Voice Agent Backend",
    description="Authentication and agent runtime for Carbon Voice Console",
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(agent.router, prefix="/api/agent", tags=["agent"])

@app.on_event("startup")
async def startup():
    await create_tables()

@app.get("/")
async def root():
    return {"status": "ok", "message": "Carbon Voice Agent Backend"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
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

    # Stytch
    STYTCH_PROJECT_ID: str
    STYTCH_SECRET: str
    STYTCH_ENVIRONMENT: str = "test"

    # OAuth Encryption
    OAUTH_ENCRYPTION_KEY: str

    # MCP
    CARBON_VOICE_MCP_URL: str

    # Frontend
    CORS_ORIGINS: List[str] = ["http://localhost:3000"]

    # JWT
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_MINUTES: int = 60 * 24  # 24 hours

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
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    stytch_user_id = Column(String, unique=True, nullable=False, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    is_active = Column(Boolean, default=True)
```

**File**: `backend/app/models/oauth_token.py`

```python
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid
from app.database import Base

class OAuthToken(Base):
    __tablename__ = "oauth_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # Which service: "github", "google", "slack", "carbon_voice", etc.
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
    user = relationship("User", backref="oauth_tokens")

    class Meta:
        # Composite unique constraint: one token per user per provider
        unique_together = [["user_id", "provider"]]
```

#### 3. Alembic Setup

**File**: `backend/alembic.ini`

```ini
[alembic]
script_location = alembic
prepend_sys_path = .
version_path_separator = os

[alembic:exclude]
tables = spatial_ref_sys

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

**File**: `backend/alembic/env.py`

```python
from logging.config import fileConfig
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from alembic import context
import asyncio

from app.config import settings
from app.database import Base
from app.models import user, oauth_token  # Import all models

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()

async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

#### 4. Initial Migration

Run after creating all model files:

```bash
cd backend
alembic revision --autogenerate -m "Initial migration: users and oauth_tokens tables"
```

### Success Criteria

#### Automated Verification:
- [ ] Backend dependencies install successfully: `pip install -r backend/requirements.txt`
- [ ] PostgreSQL database is running and accessible: `psql -U user -d carbon_voice_db -c "SELECT 1"`
- [ ] Environment variables load correctly: `python -c "from app.config import settings; print(settings.DATABASE_URL)"`
- [ ] Database migrations generate: `alembic revision --autogenerate -m "test"`
- [ ] Database migrations apply: `alembic upgrade head`
- [ ] FastAPI server starts: `uvicorn main:app --reload`
- [ ] Health check returns 200: `curl http://localhost:8000/health`

#### Manual Verification:
- [ ] Database tables created correctly in PostgreSQL
- [ ] `.env` file configured with all required variables
- [ ] Alembic version table exists in database
- [ ] Server logs show no errors on startup
- [ ] API docs accessible at `http://localhost:8000/docs`

**Implementation Note**: After all automated verifications pass and manual testing confirms the backend infrastructure is working, pause here for confirmation before proceeding to Phase 2.

---

## Phase 2: Stytch User Authentication

### Overview
Implement Stytch-based user registration, login, and JWT session management. Users can authenticate via email/password or social login (Google, GitHub). Backend issues JWT tokens for subsequent requests.

### Changes Required

#### 1. JWT and Security Utilities

**File**: `backend/app/core/security.py`

```python
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.JWT_EXPIRATION_MINUTES)

    to_encode.update({"exp": expire, "iat": datetime.utcnow()})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except JWTError:
        raise ValueError("Invalid token")

def get_user_id_from_token(token: str) -> str:
    payload = verify_token(token)
    user_id: str = payload.get("sub")
    if user_id is None:
        raise ValueError("Invalid token payload")
    return user_id
```

#### 2. Pydantic Schemas

**File**: `backend/app/schemas/auth.py`

```python
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserRegister(BaseModel):
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class SocialLoginRequest(BaseModel):
    provider: str  # "google" or "github"
    code: str  # OAuth authorization code from Stytch

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: "UserResponse"

class UserResponse(BaseModel):
    id: str
    email: str
    name: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class StytchCallbackRequest(BaseModel):
    token: str  # Magic link token or OAuth token from Stytch
```

#### 3. Authentication Service

**File**: `backend/app/services/auth_service.py`

```python
import stytch
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.user import User
from app.config import settings
from app.schemas.auth import UserRegister, UserLogin
from typing import Optional
import uuid

# Initialize Stytch client
stytch_client = stytch.Client(
    project_id=settings.STYTCH_PROJECT_ID,
    secret=settings.STYTCH_SECRET,
    environment=settings.STYTCH_ENVIRONMENT,
)

class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_user(self, user_data: UserRegister) -> User:
        """Register a new user via Stytch email/password"""

        # Create user in Stytch
        stytch_response = stytch_client.passwords.create(
            email=user_data.email,
            password=user_data.password,
        )

        # Create user in our database
        user = User(
            id=uuid.uuid4(),
            stytch_user_id=stytch_response.user_id,
            email=user_data.email,
        )

        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        return user

    async def login_user(self, credentials: UserLogin) -> User:
        """Authenticate user via Stytch email/password"""

        # Authenticate with Stytch
        stytch_response = stytch_client.passwords.authenticate(
            email=credentials.email,
            password=credentials.password,
        )

        # Get or create user in our database
        user = await self._get_or_create_user_from_stytch(stytch_response.user)

        return user

    async def authenticate_magic_link(self, token: str) -> User:
        """Authenticate user via Stytch magic link"""

        stytch_response = stytch_client.magic_links.authenticate(
            token=token,
        )

        user = await self._get_or_create_user_from_stytch(stytch_response.user)
        return user

    async def authenticate_oauth(self, token: str) -> User:
        """Authenticate user via Stytch OAuth (Google/GitHub social login)"""

        stytch_response = stytch_client.oauth.authenticate(
            token=token,
        )

        user = await self._get_or_create_user_from_stytch(stytch_response.user)
        return user

    async def _get_or_create_user_from_stytch(self, stytch_user) -> User:
        """Get existing user or create new one from Stytch user object"""

        # Try to find existing user
        result = await self.db.execute(
            select(User).where(User.stytch_user_id == stytch_user.user_id)
        )
        user = result.scalars().first()

        if user:
            return user

        # Create new user
        user = User(
            id=uuid.uuid4(),
            stytch_user_id=stytch_user.user_id,
            email=stytch_user.emails[0].email if stytch_user.emails else None,
            name=stytch_user.name.first_name if hasattr(stytch_user, 'name') else None,
        )

        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        return user

    async def get_user_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        """Get user by UUID"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalars().first()
```

#### 4. Authentication Endpoints

**File**: `backend/app/api/deps.py`

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.core.security import get_user_id_from_token
from app.services.auth_service import AuthService
from app.models.user import User
import uuid

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Get current authenticated user from JWT token"""

    token = credentials.credentials

    try:
        user_id_str = get_user_id_from_token(token)
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )

    auth_service = AuthService(db)
    user = await auth_service.get_user_by_id(user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )

    return user
```

**File**: `backend/app/api/auth.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.services.auth_service import AuthService
from app.schemas.auth import (
    UserRegister,
    UserLogin,
    TokenResponse,
    UserResponse,
    StytchCallbackRequest,
)
from app.core.security import create_access_token
from app.config import settings
from datetime import timedelta

router = APIRouter()

@router.post("/register", response_model=TokenResponse)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user via Stytch email/password"""

    auth_service = AuthService(db)

    try:
        user = await auth_service.register_user(user_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Registration failed: {str(e)}",
        )

    # Create JWT token
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=settings.JWT_EXPIRATION_MINUTES),
    )

    return TokenResponse(
        access_token=access_token,
        expires_in=settings.JWT_EXPIRATION_MINUTES * 60,
        user=UserResponse.from_orm(user),
    )

@router.post("/login", response_model=TokenResponse)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db),
):
    """Login user via Stytch email/password"""

    auth_service = AuthService(db)

    try:
        user = await auth_service.login_user(credentials)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # Create JWT token
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=settings.JWT_EXPIRATION_MINUTES),
    )

    return TokenResponse(
        access_token=access_token,
        expires_in=settings.JWT_EXPIRATION_MINUTES * 60,
        user=UserResponse.from_orm(user),
    )

@router.post("/oauth/callback", response_model=TokenResponse)
async def oauth_callback(
    callback_data: StytchCallbackRequest,
    db: AsyncSession = Depends(get_db),
):
    """Handle Stytch OAuth callback (Google, GitHub social login)"""

    auth_service = AuthService(db)

    try:
        user = await auth_service.authenticate_oauth(callback_data.token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"OAuth authentication failed: {str(e)}",
        )

    # Create JWT token
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=settings.JWT_EXPIRATION_MINUTES),
    )

    return TokenResponse(
        access_token=access_token,
        expires_in=settings.JWT_EXPIRATION_MINUTES * 60,
        user=UserResponse.from_orm(user),
    )

@router.get("/me", response_model=UserResponse)
async def get_me(current_user = Depends(get_current_user)):
    """Get current authenticated user"""
    return UserResponse.from_orm(current_user)
```

### Success Criteria

#### Automated Verification:
- [ ] User registration creates record in both Stytch and local database: `pytest tests/test_auth.py::test_register`
- [ ] Login with valid credentials returns JWT token: `pytest tests/test_auth.py::test_login`
- [ ] Invalid credentials return 401: `pytest tests/test_auth.py::test_invalid_login`
- [ ] Protected `/me` endpoint requires valid JWT: `pytest tests/test_auth.py::test_protected_endpoint`
- [ ] Expired tokens are rejected: `pytest tests/test_auth.py::test_expired_token`

#### Manual Verification:
- [ ] User can register via Postman/curl with email and password
- [ ] Registration creates user in Stytch dashboard
- [ ] User can log in and receive JWT token
- [ ] JWT token works for authenticated endpoints
- [ ] Stytch social login (Google) redirects correctly
- [ ] OAuth callback processes Stytch token and returns JWT
- [ ] Invalid tokens return 401 Unauthorized
- [ ] User data synced correctly between Stytch and local DB

**Implementation Note**: After all verifications pass, pause for confirmation before proceeding to Phase 3.

---

## Phase 3: MCP OAuth Credential Management

### Overview
Implement OAuth broker functionality for MCP services (GitHub, Google, Slack). Users can connect external accounts via OAuth. Tokens are encrypted and stored per-user in the database. Agents can request credentials at runtime via a clean API.

### Changes Required

#### 1. Token Encryption Utility

**File**: `backend/app/core/encryption.py`

```python
from cryptography.fernet import Fernet
from app.config import settings

# Initialize Fernet cipher with encryption key from env
fernet = Fernet(settings.OAUTH_ENCRYPTION_KEY.encode())

def encrypt_token(token: str) -> str:
    """Encrypt OAuth token for database storage"""
    return fernet.encrypt(token.encode()).decode()

def decrypt_token(encrypted_token: str) -> str:
    """Decrypt OAuth token from database"""
    return fernet.decrypt(encrypted_token.encode()).decode()
```

#### 2. OAuth Service

**File**: `backend/app/services/oauth_service.py`

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.oauth_token import OAuthToken
from app.models.user import User
from app.core.encryption import encrypt_token, decrypt_token
from datetime import datetime, timedelta
from typing import Optional
import httpx
import uuid

# OAuth provider configurations
OAUTH_PROVIDERS = {
    "github": {
        "auth_url": "https://github.com/login/oauth/authorize",
        "token_url": "https://github.com/login/oauth/access_token",
        "scope": "repo,user,read:org",
    },
    "google": {
        "auth_url": "https://accounts.google.com/o/oauth2/v2/auth",
        "token_url": "https://oauth2.googleapis.com/token",
        "scope": "https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/calendar.readonly",
    },
    "slack": {
        "auth_url": "https://slack.com/oauth/v2/authorize",
        "token_url": "https://slack.com/api/oauth.v2.access",
        "scope": "channels:read,chat:write,users:read",
    },
}

class OAuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_authorization_url(
        self,
        provider: str,
        user_id: uuid.UUID,
        redirect_uri: str,
        state: str,
    ) -> str:
        """Generate OAuth authorization URL for a provider"""

        if provider not in OAUTH_PROVIDERS:
            raise ValueError(f"Unknown provider: {provider}")

        config = OAUTH_PROVIDERS[provider]

        # Build authorization URL (simplified - real implementation needs client_id from env)
        params = {
            "client_id": f"{provider.upper()}_CLIENT_ID",  # Load from env
            "redirect_uri": redirect_uri,
            "scope": config["scope"],
            "state": state,
            "response_type": "code",
        }

        query_string = "&".join(f"{k}={v}" for k, v in params.items())
        return f"{config['auth_url']}?{query_string}"

    async def exchange_code_for_token(
        self,
        provider: str,
        code: str,
        redirect_uri: str,
        user_id: uuid.UUID,
    ) -> OAuthToken:
        """Exchange OAuth authorization code for access token"""

        if provider not in OAUTH_PROVIDERS:
            raise ValueError(f"Unknown provider: {provider}")

        config = OAUTH_PROVIDERS[provider]

        # Exchange code for token
        async with httpx.AsyncClient() as client:
            response = await client.post(
                config["token_url"],
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": redirect_uri,
                    "client_id": f"{provider.upper()}_CLIENT_ID",  # Load from env
                    "client_secret": f"{provider.upper()}_CLIENT_SECRET",  # Load from env
                },
            )

            if response.status_code != 200:
                raise Exception(f"Token exchange failed: {response.text}")

            token_data = response.json()

        # Check if token already exists for this user/provider
        result = await self.db.execute(
            select(OAuthToken).where(
                OAuthToken.user_id == user_id,
                OAuthToken.provider == provider,
            )
        )
        existing_token = result.scalars().first()

        # Calculate expiration
        expires_at = None
        if "expires_in" in token_data:
            expires_at = datetime.utcnow() + timedelta(seconds=token_data["expires_in"])

        # Encrypt tokens
        access_token_encrypted = encrypt_token(token_data["access_token"])
        refresh_token_encrypted = None
        if "refresh_token" in token_data:
            refresh_token_encrypted = encrypt_token(token_data["refresh_token"])

        if existing_token:
            # Update existing token
            existing_token.access_token_encrypted = access_token_encrypted
            existing_token.refresh_token_encrypted = refresh_token_encrypted
            existing_token.expires_at = expires_at
            existing_token.scope = token_data.get("scope")
            existing_token.updated_at = datetime.utcnow()

            await self.db.commit()
            await self.db.refresh(existing_token)
            return existing_token
        else:
            # Create new token
            oauth_token = OAuthToken(
                id=uuid.uuid4(),
                user_id=user_id,
                provider=provider,
                access_token_encrypted=access_token_encrypted,
                refresh_token_encrypted=refresh_token_encrypted,
                expires_at=expires_at,
                scope=token_data.get("scope"),
            )

            self.db.add(oauth_token)
            await self.db.commit()
            await self.db.refresh(oauth_token)
            return oauth_token

    async def get_token_for_user(
        self,
        user_id: uuid.UUID,
        provider: str,
    ) -> Optional[str]:
        """Get decrypted OAuth token for a user and provider"""

        result = await self.db.execute(
            select(OAuthToken).where(
                OAuthToken.user_id == user_id,
                OAuthToken.provider == provider,
            )
        )
        oauth_token = result.scalars().first()

        if not oauth_token:
            return None

        # Check if token is expired
        if oauth_token.expires_at and oauth_token.expires_at < datetime.utcnow():
            # TODO: Implement token refresh logic
            return None

        # Decrypt and return
        return decrypt_token(oauth_token.access_token_encrypted)

    async def revoke_token(
        self,
        user_id: uuid.UUID,
        provider: str,
    ) -> bool:
        """Delete OAuth token for a user and provider"""

        result = await self.db.execute(
            select(OAuthToken).where(
                OAuthToken.user_id == user_id,
                OAuthToken.provider == provider,
            )
        )
        oauth_token = result.scalars().first()

        if oauth_token:
            await self.db.delete(oauth_token)
            await self.db.commit()
            return True

        return False
```

#### 3. OAuth Endpoints

**File**: `backend/app/api/oauth.py` (new file - add to main.py router)

```python
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.api.deps import get_current_user
from app.services.oauth_service import OAuthService
from app.models.user import User
from pydantic import BaseModel

router = APIRouter()

class OAuthAuthorizationRequest(BaseModel):
    provider: str  # "github", "google", "slack"
    redirect_uri: str

class OAuthCallbackRequest(BaseModel):
    provider: str
    code: str
    redirect_uri: str

@router.post("/authorize")
async def start_oauth_flow(
    request: OAuthAuthorizationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Start OAuth flow for connecting an external service"""

    oauth_service = OAuthService(db)

    try:
        # Generate state token (should store this for validation)
        state = f"{current_user.id}:{request.provider}"

        auth_url = await oauth_service.get_authorization_url(
            provider=request.provider,
            user_id=current_user.id,
            redirect_uri=request.redirect_uri,
            state=state,
        )

        return {"authorization_url": auth_url, "state": state}
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )

@router.post("/callback")
async def oauth_callback(
    request: OAuthCallbackRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Handle OAuth callback and store tokens"""

    oauth_service = OAuthService(db)

    try:
        oauth_token = await oauth_service.exchange_code_for_token(
            provider=request.provider,
            code=request.code,
            redirect_uri=request.redirect_uri,
            user_id=current_user.id,
        )

        return {
            "success": True,
            "provider": oauth_token.provider,
            "message": f"Successfully connected {request.provider}",
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"OAuth callback failed: {str(e)}",
        )

@router.delete("/{provider}")
async def disconnect_provider(
    provider: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Disconnect an OAuth provider"""

    oauth_service = OAuthService(db)

    success = await oauth_service.revoke_token(
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
async def get_connections(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get list of connected OAuth providers for current user"""

    from sqlalchemy.future import select
    from app.models.oauth_token import OAuthToken

    result = await db.execute(
        select(OAuthToken).where(OAuthToken.user_id == current_user.id)
    )
    tokens = result.scalars().all()

    return {
        "connections": [
            {
                "provider": token.provider,
                "connected_at": token.created_at,
                "expires_at": token.expires_at,
            }
            for token in tokens
        ]
    }
```

**Update**: `backend/main.py` to include OAuth router:

```python
from app.api import auth, agent, oauth  # Add oauth import

app.include_router(oauth.router, prefix="/api/oauth", tags=["oauth"])
```

### Success Criteria

#### Automated Verification:
- [ ] OAuth authorization URL generation works: `pytest tests/test_oauth.py::test_authorization_url`
- [ ] Token encryption/decryption works correctly: `pytest tests/test_encryption.py`
- [ ] Token exchange stores encrypted tokens in database: `pytest tests/test_oauth.py::test_token_exchange`
- [ ] Get token for user returns decrypted token: `pytest tests/test_oauth.py::test_get_token`
- [ ] Expired tokens are detected: `pytest tests/test_oauth.py::test_expired_token`
- [ ] Token revocation deletes from database: `pytest tests/test_oauth.py::test_revoke_token`

#### Manual Verification:
- [ ] User can initiate GitHub OAuth flow via API
- [ ] OAuth callback successfully stores GitHub token
- [ ] `/api/oauth/connections` lists connected providers
- [ ] Tokens are stored encrypted in database (verify in PostgreSQL)
- [ ] User can disconnect a provider
- [ ] Multiple users can have separate tokens for same provider
- [ ] Token refresh works (if provider supports it)

**Implementation Note**: After all verifications pass, pause for confirmation before proceeding to Phase 4.

---

## Phase 4: Agent Runtime Integration

### Overview
Embed Google ADK agents into the FastAPI backend. Create an agent service that accepts user requests, loads user-specific MCP credentials, invokes the appropriate agent, and streams responses back to the client via SSE.

### Changes Required

#### 1. Agent Credentials Provider

**File**: `backend/app/services/agent_credentials_provider.py`

```python
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.oauth_service import OAuthService
from typing import Optional, Dict
import uuid

class AgentCredentialsProvider:
    """
    Provides MCP credentials to agents at runtime.
    Agents call this to get user-specific OAuth tokens.
    """

    def __init__(self, db: AsyncSession, user_id: uuid.UUID):
        self.db = db
        self.user_id = user_id
        self.oauth_service = OAuthService(db)

    async def get_credential(self, provider: str) -> Optional[str]:
        """
        Get OAuth credential for a specific provider.
        Returns None if user hasn't connected this provider.

        Args:
            provider: "github", "google", "slack", etc.

        Returns:
            Decrypted access token or None
        """
        return await self.oauth_service.get_token_for_user(
            user_id=self.user_id,
            provider=provider,
        )

    async def get_all_credentials(self) -> Dict[str, str]:
        """
        Get all connected credentials for the user.

        Returns:
            Dict mapping provider name to access token
        """
        from sqlalchemy.future import select
        from app.models.oauth_token import OAuthToken
        from app.core.encryption import decrypt_token

        result = await self.db.execute(
            select(OAuthToken).where(OAuthToken.user_id == self.user_id)
        )
        tokens = result.scalars().all()

        credentials = {}
        for token in tokens:
            try:
                credentials[token.provider] = decrypt_token(token.access_token_encrypted)
            except Exception:
                # Skip expired or invalid tokens
                continue

        return credentials

    def has_credential(self, provider: str) -> bool:
        """Check if user has connected a specific provider (sync check)"""
        # This would need to be async in practice
        # For now, agents should use get_credential and check for None
        pass
```

#### 2. Agent Service

**File**: `backend/app/services/agent_service.py`

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import SseConnectionParams
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.agent_credentials_provider import AgentCredentialsProvider
from app.config import settings
from typing import AsyncIterator, Dict, Any
import uuid
import asyncio
import json

# Import existing agent definitions
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "../../.."))

from carbon_agent.agent import root_agent  # Import from existing agent code

class MissingCredentialError(Exception):
    """Raised when agent needs a credential that user hasn't connected"""
    def __init__(self, provider: str, message: str = None):
        self.provider = provider
        self.message = message or f"Missing credential for {provider}"
        super().__init__(self.message)

class AgentService:
    """
    Service for invoking Google ADK agents with user-specific MCP credentials.
    Handles credential injection and error handling for missing credentials.
    """

    def __init__(self, db: AsyncSession, user_id: uuid.UUID):
        self.db = db
        self.user_id = user_id
        self.credentials_provider = AgentCredentialsProvider(db, user_id)

    async def chat(
        self,
        message: str,
        session_id: str,
        context: Dict[str, Any] = None,
    ) -> AsyncIterator[str]:
        """
        Send a message to the agent and stream responses.

        Args:
            message: User's message
            session_id: Chat session ID
            context: Additional context for the agent

        Yields:
            SSE-formatted response chunks

        Raises:
            MissingCredentialError: If agent needs a credential user hasn't connected
        """

        # Load user's MCP credentials
        credentials = await self.credentials_provider.get_all_credentials()

        # Create agent with user's credentials injected
        # This is a simplified example - real implementation would configure
        # MCP tools with the user's tokens

        try:
            # Invoke agent (this is pseudo-code - actual ADK invocation differs)
            # The agent would use MCP tools configured with user credentials

            # Example: Configure Carbon Voice MCP with user's token
            carbon_voice_token = credentials.get("carbon_voice")
            if not carbon_voice_token:
                raise MissingCredentialError("carbon_voice")

            # Stream agent responses
            async for chunk in self._invoke_agent(message, session_id, credentials):
                yield self._format_sse(chunk)

        except MissingCredentialError:
            # Re-raise to be handled by endpoint
            raise
        except Exception as e:
            # Handle other agent errors
            yield self._format_sse({
                "type": "error",
                "message": f"Agent error: {str(e)}",
            })

    async def _invoke_agent(
        self,
        message: str,
        session_id: str,
        credentials: Dict[str, str],
    ) -> AsyncIterator[Dict[str, Any]]:
        """
        Internal method to invoke Google ADK agent.
        This is where we'd integrate with actual ADK runtime.
        """

        # Placeholder implementation
        # Real implementation would:
        # 1. Configure MCP tools with user credentials
        # 2. Invoke root_agent with message
        # 3. Stream back agent responses

        yield {
            "type": "message",
            "content": "Agent is processing your request...",
            "session_id": session_id,
        }

        await asyncio.sleep(1)

        yield {
            "type": "message",
            "content": f"Response to: {message}",
            "session_id": session_id,
        }

        yield {
            "type": "done",
            "session_id": session_id,
        }

    def _format_sse(self, data: Dict[str, Any]) -> str:
        """Format data as Server-Sent Event"""
        return f"data: {json.dumps(data)}\n\n"
```

#### 3. Agent Chat Endpoints

**File**: `backend/app/schemas/agent.py`

```python
from pydantic import BaseModel
from typing import Optional, Dict, Any

class ChatRequest(BaseModel):
    message: str
    session_id: str
    context: Optional[Dict[str, Any]] = None

class ChatSession(BaseModel):
    id: str
    user_id: str
    created_at: str
    updated_at: str

class MissingCredentialResponse(BaseModel):
    error: str = "missing_credential"
    provider: str
    message: str
    authorization_url: Optional[str] = None
```

**File**: `backend/app/api/agent.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.api.deps import get_current_user
from app.services.agent_service import AgentService, MissingCredentialError
from app.services.oauth_service import OAuthService
from app.schemas.agent import ChatRequest, MissingCredentialResponse
from app.models.user import User

router = APIRouter()

@router.post("/chat")
async def agent_chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Send a message to the agent and receive streaming responses via SSE.

    Returns:
        SSE stream of agent responses

    Raises:
        401 with missing_credential if user needs to connect a service
    """

    agent_service = AgentService(db, current_user.id)

    try:
        async def event_generator():
            async for event in agent_service.chat(
                message=request.message,
                session_id=request.session_id,
                context=request.context,
            ):
                yield event

        return StreamingResponse(
            event_generator(),
            media_type="text/event-stream",
        )

    except MissingCredentialError as e:
        # Return structured error with provider info
        oauth_service = OAuthService(db)

        # Generate authorization URL for missing provider
        auth_url = await oauth_service.get_authorization_url(
            provider=e.provider,
            user_id=current_user.id,
            redirect_uri=f"https://carbonconsole.ngrok.app/oauth/callback/{e.provider}",
            state=f"{current_user.id}:{e.provider}",
        )

        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=MissingCredentialResponse(
                provider=e.provider,
                message=e.message,
                authorization_url=auth_url,
            ).dict(),
        )

@router.get("/sessions")
async def get_sessions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all chat sessions for current user"""
    # TODO: Implement session persistence
    return {"sessions": []}

@router.post("/sessions")
async def create_session(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new chat session"""
    # TODO: Implement session creation
    import uuid
    session_id = str(uuid.uuid4())
    return {"session_id": session_id}
```

### Success Criteria

#### Automated Verification:
- [ ] Agent credentials provider retrieves user tokens: `pytest tests/test_agent_service.py::test_credentials_provider`
- [ ] Missing credential raises MissingCredentialError: `pytest tests/test_agent_service.py::test_missing_credential`
- [ ] Agent chat endpoint returns SSE stream: `pytest tests/test_agent_endpoints.py::test_chat_stream`
- [ ] Missing credential returns 401 with provider info: `pytest tests/test_agent_endpoints.py::test_missing_credential_response`

#### Manual Verification:
- [ ] User can send message to agent via API
- [ ] Agent responses stream via SSE
- [ ] When agent needs GitHub, API returns 401 with GitHub authorization URL
- [ ] After connecting GitHub, same message succeeds
- [ ] Agent can access multiple MCP services if user has connected them
- [ ] Different users have isolated credentials
- [ ] Agent errors are handled gracefully

**Implementation Note**: After all verifications pass, pause for confirmation before proceeding to Phase 5.

---

## Phase 5: Flutter Client Integration

### Overview
Update the Flutter client to use the new backend authentication system. Replace direct Carbon Voice OAuth with Stytch authentication, implement JWT token management, add SSE client for agent chat, and handle missing credential prompts.

### Changes Required

#### 1. Update Dependencies

**File**: `carbon_voice_console/pubspec.yaml`

Add/update dependencies:

```yaml
dependencies:
  # Existing dependencies...

  # Stytch Flutter SDK
  stytch_flutter: ^2.0.0

  # SSE client for agent chat
  eventsource: ^1.0.0

  # JWT handling
  dart_jsonwebtoken: ^2.12.0

  # Updated HTTP client
  http: ^1.2.0
```

#### 2. Backend API Configuration

**File**: `carbon_voice_console/lib/core/config/backend_config.dart` (new file)

```dart
class BackendConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiVersion = 'api';

  // Endpoints
  static String get authRegister => '$baseUrl/$apiVersion/auth/register';
  static String get authLogin => '$baseUrl/$apiVersion/auth/login';
  static String get authMe => '$baseUrl/$apiVersion/auth/me';
  static String get authOAuthCallback => '$baseUrl/$apiVersion/auth/oauth/callback';

  static String get oauthAuthorize => '$baseUrl/$apiVersion/oauth/authorize';
  static String get oauthCallback => '$baseUrl/$apiVersion/oauth/callback';
  static String get oauthConnections => '$baseUrl/$apiVersion/oauth/connections';

  static String get agentChat => '$baseUrl/$apiVersion/agent/chat';
  static String get agentSessions => '$baseUrl/$apiVersion/agent/sessions';
}
```

#### 3. JWT Token Storage

**File**: `carbon_voice_console/lib/features/auth/data/datasources/jwt_local_datasource.dart` (new file)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class JwtLocalDataSource {
  final _storage = const FlutterSecureStorage();

  static const _jwtKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveJwtToken(String token) async {
    await _storage.write(key: _jwtKey, value: token);
  }

  Future<String?> loadJwtToken() async {
    return await _storage.read(key: _jwtKey);
  }

  Future<void> deleteJwtToken() async {
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await loadJwtToken();
    if (token == null) return false;

    // TODO: Add JWT expiration check
    return true;
  }
}
```

#### 4. Backend Auth Repository

**File**: `carbon_voice_console/lib/features/auth/domain/repositories/backend_auth_repository.dart` (new file)

```dart
import 'package:carbon_voice_console/core/utils/result.dart';

abstract class BackendAuthRepository {
  Future<Result<AuthResponse>> register(String email, String password);
  Future<Result<AuthResponse>> login(String email, String password);
  Future<Result<AuthResponse>> loginWithStytchOAuth(String token);
  Future<Result<UserProfile>> getCurrentUser();
  Future<Result<void>> logout();
  Future<Result<bool>> isAuthenticated();
}

class AuthResponse {
  final String accessToken;
  final int expiresIn;
  final UserProfile user;

  AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      expiresIn: json['expires_in'],
      user: UserProfile.fromJson(json['user']),
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? name;

  UserProfile({required this.id, required this.email, this.name});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'],
    );
  }
}
```

**File**: `carbon_voice_console/lib/features/auth/data/repositories/backend_auth_repository_impl.dart` (new file)

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/backend_config.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:carbon_voice_console/features/auth/domain/repositories/backend_auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: BackendAuthRepository)
class BackendAuthRepositoryImpl implements BackendAuthRepository {
  final JwtLocalDataSource _jwtDataSource;
  final Logger _logger;

  BackendAuthRepositoryImpl(this._jwtDataSource, this._logger);

  @override
  Future<Result<AuthResponse>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.authRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _jwtDataSource.saveJwtToken(authResponse.accessToken);
        return success(authResponse);
      } else {
        return failure(AuthFailure(
          code: 'REGISTER_FAILED',
          details: response.body,
        ));
      }
    } catch (e) {
      _logger.e('Registration error', error: e);
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<AuthResponse>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _jwtDataSource.saveJwtToken(authResponse.accessToken);
        return success(authResponse);
      } else {
        return failure(AuthFailure(
          code: 'LOGIN_FAILED',
          details: response.body,
        ));
      }
    } catch (e) {
      _logger.e('Login error', error: e);
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<AuthResponse>> loginWithStytchOAuth(String token) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.authOAuthCallback),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _jwtDataSource.saveJwtToken(authResponse.accessToken);
        return success(authResponse);
      } else {
        return failure(AuthFailure(
          code: 'OAUTH_FAILED',
          details: response.body,
        ));
      }
    } catch (e) {
      _logger.e('OAuth login error', error: e);
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> getCurrentUser() async {
    try {
      final token = await _jwtDataSource.loadJwtToken();
      if (token == null) {
        return failure(AuthFailure(code: 'NO_TOKEN', details: 'Not authenticated'));
      }

      final response = await http.get(
        Uri.parse(BackendConfig.authMe),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final user = UserProfile.fromJson(jsonDecode(response.body));
        return success(user);
      } else {
        return failure(AuthFailure(
          code: 'GET_USER_FAILED',
          details: response.body,
        ));
      }
    } catch (e) {
      _logger.e('Get user error', error: e);
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    await _jwtDataSource.deleteJwtToken();
    return success(null);
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    final hasToken = await _jwtDataSource.hasValidToken();
    return success(hasToken);
  }
}
```

#### 5. SSE Agent Chat Client

**File**: `carbon_voice_console/lib/features/agent_chat/data/datasources/agent_chat_sse_datasource.dart` (new file)

```dart
import 'dart:async';
import 'dart:convert';
import 'package:carbon_voice_console/core/config/backend_config.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:eventsource/eventsource.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton()
class AgentChatSseDataSource {
  final JwtLocalDataSource _jwtDataSource;
  final Logger _logger;

  AgentChatSseDataSource(this._jwtDataSource, this._logger);

  Stream<AgentChatMessage> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async* {
    final token = await _jwtDataSource.loadJwtToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      // Create SSE connection
      final eventSource = await EventSource.connect(
        Uri.parse(BackendConfig.agentChat),
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': content,
          'session_id': sessionId,
          'context': context,
        }),
      );

      await for (final event in eventSource) {
        if (event.data == null) continue;

        try {
          final data = jsonDecode(event.data!);

          if (data['type'] == 'message') {
            yield AgentChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              sessionId: sessionId,
              role: MessageRole.agent,
              content: data['content'],
              timestamp: DateTime.now(),
              subAgentName: data['sub_agent_name'],
            );
          } else if (data['type'] == 'done') {
            break;
          } else if (data['type'] == 'error') {
            throw Exception(data['message']);
          }
        } catch (e) {
          _logger.e('Error parsing SSE event', error: e);
        }
      }
    } on http.ClientException catch (e) {
      // Check if 401 with missing_credential
      if (e.message.contains('401')) {
        // Parse error response to get missing provider
        // Flutter should catch this and prompt OAuth connection
        rethrow;
      }
      _logger.e('SSE connection error', error: e);
      rethrow;
    }
  }
}
```

#### 6. Update Agent Chat Repository

**File**: `carbon_voice_console/lib/features/agent_chat/data/repositories/agent_chat_repository_impl.dart`

Replace mock implementation with real SSE-based implementation:

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/agent_chat/data/datasources/agent_chat_sse_datasource.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/agent_chat_message.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/repositories/agent_chat_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: AgentChatRepository)
class AgentChatRepositoryImpl implements AgentChatRepository {
  final AgentChatSseDataSource _sseDataSource;
  final Map<String, List<AgentChatMessage>> _localMessages = {};
  final Uuid _uuid = const Uuid();

  AgentChatRepositoryImpl(this._sseDataSource);

  @override
  Future<Result<List<AgentChatMessage>>> loadMessages(String sessionId) async {
    return success(_localMessages[sessionId]?.toList() ?? []);
  }

  @override
  Future<Result<List<AgentChatMessage>>> sendMessage({
    required String sessionId,
    required String content,
    Map<String, dynamic>? context,
  }) async {
    try {
      final messages = <AgentChatMessage>[];

      // Stream agent responses
      await for (final message in _sseDataSource.sendMessage(
        sessionId: sessionId,
        content: content,
        context: context,
      )) {
        messages.add(message);

        // Save locally
        _localMessages[sessionId] ??= [];
        _localMessages[sessionId]!.add(message);
      }

      return success(messages);
    } catch (e) {
      return failure(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveMessagesLocally(
    String sessionId,
    List<AgentChatMessage> messages,
  ) async {
    _localMessages[sessionId] = messages;
    return success(null);
  }
}
```

#### 7. OAuth Connection UI

**File**: `carbon_voice_console/lib/features/settings/presentation/components/connected_services_section.dart` (new file)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectedServicesSection extends StatelessWidget {
  const ConnectedServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected Services',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildServiceTile(
          context,
          provider: 'github',
          icon: Icons.code,
          name: 'GitHub',
          connected: false,
        ),
        _buildServiceTile(
          context,
          provider: 'google',
          icon: Icons.cloud,
          name: 'Google Drive',
          connected: false,
        ),
        _buildServiceTile(
          context,
          provider: 'slack',
          icon: Icons.chat,
          name: 'Slack',
          connected: false,
        ),
      ],
    );
  }

  Widget _buildServiceTile(
    BuildContext context, {
    required String provider,
    required IconData icon,
    required String name,
    required bool connected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      trailing: connected
          ? ElevatedButton(
              onPressed: () {
                // Disconnect provider
              },
              child: const Text('Disconnect'),
            )
          : ElevatedButton(
              onPressed: () {
                // Start OAuth flow for provider
                _connectService(context, provider);
              },
              child: const Text('Connect'),
            ),
    );
  }

  void _connectService(BuildContext context, String provider) {
    // This would trigger OAuth flow via backend
    // Implementation depends on auth BLoC
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Flutter app compiles successfully: `flutter build web`
- [ ] All unit tests pass: `flutter test`
- [ ] JWT token storage works: `flutter test test/auth/jwt_storage_test.dart`
- [ ] Backend API client makes authenticated requests: `flutter test test/auth/backend_api_test.dart`

#### Manual Verification:
- [ ] User can register with email/password via new backend
- [ ] User can log in and JWT token is stored
- [ ] Protected routes require JWT token
- [ ] Agent chat sends messages and receives SSE responses
- [ ] When agent needs GitHub, Flutter shows "Connect GitHub" dialog
- [ ] User clicks "Connect GitHub" and completes OAuth flow
- [ ] After connection, agent chat works with GitHub tools
- [ ] User can view connected services in settings
- [ ] User can disconnect a service
- [ ] Logout clears JWT token and redirects to login

**Implementation Note**: This is the final phase. After all verifications pass and the full flow works end-to-end, the authentication layer implementation is complete.

---

## Testing Strategy

### Unit Tests

**Backend Tests** (`backend/tests/`):
- `test_auth.py`: Stytch authentication flows, JWT generation, token validation
- `test_oauth.py`: OAuth authorization URLs, token exchange, encryption/decryption
- `test_agent_service.py`: Credential provider, agent invocation, error handling
- `test_encryption.py`: Token encryption/decryption utilities
- `test_models.py`: Database model validation, relationships

**Flutter Tests** (`carbon_voice_console/test/`):
- `auth/jwt_storage_test.dart`: JWT token storage and retrieval
- `auth/backend_api_test.dart`: Backend API client authentication
- `agent_chat/sse_client_test.dart`: SSE connection and event parsing
- `oauth/oauth_flow_test.dart`: OAuth connection flow

### Integration Tests

**End-to-End Authentication Flow** (`backend/tests/integration/`):
1. Register user via Stytch
2. Verify user created in database
3. Login and receive JWT
4. Access protected endpoint with JWT
5. Token expiration handling

**OAuth Connection Flow**:
1. User initiates OAuth for GitHub
2. Backend returns authorization URL
3. Simulate OAuth callback
4. Verify token stored encrypted in database
5. Agent retrieves token successfully

**Agent Chat with MCP**:
1. User sends message requiring GitHub access
2. Backend detects missing credential
3. Returns 401 with provider info
4. User connects GitHub
5. Retry message successfully uses GitHub MCP tools

### Manual Testing Steps

**Phase 2 - Authentication**:
1. Open Stytch dashboard and verify project configuration
2. Register a new user via Postman
3. Check database for user record
4. Login with credentials
5. Copy JWT token and test `/api/auth/me` endpoint
6. Test social login with Google

**Phase 3 - OAuth**:
1. Call `/api/oauth/authorize` for GitHub
2. Follow authorization URL in browser
3. Complete GitHub OAuth
4. Verify callback stores token in database
5. Check PostgreSQL for encrypted token
6. Call `/api/oauth/connections` to list providers

**Phase 4 - Agent Runtime**:
1. Send message to `/api/agent/chat` with valid JWT
2. Observe SSE stream in browser or curl
3. Send message requiring GitHub without connecting it first
4. Verify 401 response with missing_credential error
5. Connect GitHub and retry
6. Verify agent successfully uses GitHub MCP tools

**Phase 5 - Flutter**:
1. Run Flutter app and register new account
2. Verify login works and stores JWT
3. Navigate to agent chat
4. Send message and observe streaming responses
5. Trigger missing credential error
6. Complete OAuth connection flow
7. Retry and verify success
8. Test disconnect service
9. Test logout

## Performance Considerations

### Database Optimization
- Index on `users.stytch_user_id` and `users.email` for fast lookups
- Index on `oauth_tokens.user_id` and `oauth_tokens.provider` for credential queries
- Use connection pooling for PostgreSQL (SQLAlchemy handles this)
- Consider read replicas if scaling beyond single instance

### Token Encryption
- Fernet encryption is fast but consider caching decrypted tokens in memory for agent runtime
- Implement token rotation strategy to minimize exposure window
- Use separate encryption keys for different token types

### SSE Streaming
- Set appropriate timeout values for long-running agent tasks
- Implement heartbeat mechanism to keep connections alive
- Consider connection limits per user to prevent abuse
- Use async/await throughout to avoid blocking

### Agent Invocation
- Cache agent instances to avoid re-initialization overhead
- Implement request queuing if agents can't handle concurrent requests
- Set timeouts for agent responses to prevent infinite hangs
- Monitor memory usage of ADK runtime

### Frontend Optimization
- Implement token refresh before expiration to avoid interruptions
- Cache user profile to reduce `/api/auth/me` calls
- Debounce agent chat input to avoid spamming backend
- Use pagination for chat message history

## Migration Notes

### Migrating Existing Users

If there are existing users authenticating directly to Carbon Voice API:

1. **No automatic migration** - Users must re-register via Stytch
2. **Data continuity**: User data remains in Carbon Voice backend, accessed via MCP
3. **Communication strategy**: Notify users of new authentication system
4. **Transition period**: Consider supporting both old and new auth temporarily

### Database Migration

**From**: No backend database
**To**: PostgreSQL with users and oauth_tokens tables

Steps:
1. Create PostgreSQL database
2. Run Alembic migrations: `alembic upgrade head`
3. Verify tables created correctly
4. Test with sample data before production deployment

### Environment Variables

**Backend** (`.env`):
```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/carbon_voice_db
STYTCH_PROJECT_ID=project-live-xxx
STYTCH_SECRET=secret-live-xxx
STYTCH_ENVIRONMENT=live
OAUTH_ENCRYPTION_KEY=<generate with Fernet.generate_key()>
SECRET_KEY=<generate with openssl rand -hex 32>
```

**Flutter** (build args):
```bash
flutter build web \
  --dart-define=BACKEND_BASE_URL=https://api.yourbackend.com \
  --dart-define=STYTCH_PUBLIC_TOKEN=public-token-live-xxx
```

### Deployment Checklist

**Backend**:
- [ ] PostgreSQL database provisioned and accessible
- [ ] Environment variables configured in hosting platform
- [ ] Database migrations run: `alembic upgrade head`
- [ ] CORS origins configured for Flutter client domain
- [ ] SSL/TLS certificates configured
- [ ] Health check endpoint responding
- [ ] Logging and monitoring configured

**Flutter**:
- [ ] Backend URL configured via build args
- [ ] Stytch public token configured
- [ ] OAuth redirect URIs whitelisted in Stytch dashboard
- [ ] OAuth redirect URIs whitelisted in provider dashboards (GitHub, Google)
- [ ] Build and deploy: `flutter build web --release`

## References

- **Stytch Documentation**: https://stytch.com/docs
- **Google ADK Documentation**: https://github.com/googleapis/agent-development-kit
- **FastAPI Documentation**: https://fastapi.tiangolo.com
- **SQLAlchemy Async**: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- **Model Context Protocol**: https://modelcontextprotocol.io
- **SSE-Starlette**: https://github.com/sysid/sse-starlette

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Auth BLoC    │  │ Agent Chat   │  │ OAuth        │          │
│  │ (Stytch)     │  │ BLoC (SSE)   │  │ Connection   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
└─────────┼─────────────────┼─────────────────┼───────────────────┘
          │                 │                 │
          │ JWT Token       │ SSE Stream      │ OAuth Flow
          │                 │                 │
┌─────────▼─────────────────▼─────────────────▼───────────────────┐
│                     FastAPI Backend                             │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  /api/auth/*        - Stytch authentication            │    │
│  │  /api/oauth/*       - OAuth broker for MCP services    │    │
│  │  /api/agent/chat    - Agent invocation with SSE        │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Auth Service │  │ OAuth Service│  │ Agent Service│          │
│  │ (Stytch SDK) │  │ (Token Mgmt) │  │ (ADK Runtime)│          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         ▼                 ▼                 │                   │
│  ┌─────────────────────────────────┐       │                   │
│  │      PostgreSQL Database        │       │                   │
│  │  ┌─────────────┐ ┌────────────┐│       │                   │
│  │  │   users     │ │oauth_tokens││       │                   │
│  │  └─────────────┘ └────────────┘│       │                   │
│  └─────────────────────────────────┘       │                   │
│                                             │                   │
│  ┌──────────────────────────────────────┐  │                   │
│  │      Google ADK Agent Runtime        │◄─┘                   │
│  │  ┌──────────┐  ┌──────────────────┐ │                      │
│  │  │Root Agent│  │ MCP Tools        │ │                      │
│  │  │          ├─►│ (with user creds)│ │                      │
│  │  └──────────┘  └──────────────────┘ │                      │
│  └──────────────────────────────────────┘                      │
└─────────────────────────────────┬───────────────────────────────┘
                                  │
                                  │ MCP Protocol
                                  │
┌─────────────────────────────────▼───────────────────────────────┐
│                      External MCP Servers                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ GitHub MCP   │  │ Google MCP   │  │ Carbon Voice │          │
│  │ Server       │  │ Server       │  │ MCP Server   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Security Considerations

### Secrets Management
- Never commit `.env` files to version control
- Use environment variables for all secrets (Stytch keys, database credentials, encryption keys)
- Rotate encryption keys periodically
- Use separate Stytch projects for development and production

### Token Security
- Store OAuth tokens encrypted at rest using Fernet
- Use HTTPS for all API communication
- Set appropriate JWT expiration times (24 hours recommended)
- Implement token refresh before expiration
- Clear tokens on logout

### OAuth Security
- Validate state parameter on OAuth callbacks to prevent CSRF
- Use PKCE for OAuth flows where supported
- Whitelist redirect URIs in provider dashboards
- Implement rate limiting on OAuth endpoints

### Database Security
- Use parameterized queries (SQLAlchemy handles this)
- Encrypt sensitive columns (oauth_tokens)
- Implement row-level security if multiple tenants
- Regular database backups
- Restrict database access to backend only

### API Security
- Require JWT for all protected endpoints
- Validate JWT signature and expiration
- Implement rate limiting to prevent abuse
- Log authentication failures
- Use CORS to restrict allowed origins
