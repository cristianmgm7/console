# OAuth 2.0 Flow Explained Simply

## The Basic Idea

OAuth 2.0 is a **two-step process**:
1. **Step 1**: Get an **authorization code** (temporary, one-time use)
2. **Step 2**: Exchange that code for an **access token** (what you actually use)

Think of it like this:
- **Authorization Code** = A temporary ticket that proves "the user said yes"
- **Access Token** = The actual key to access the user's data

---

## Step-by-Step Flow

### Step 1: Request Authorization Code

**What you send:**
```
GET https://api.carbonvoice.app/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=http://localhost:3000/auth/callback
  &code_challenge=ABC123...          (PKCE security)
  &code_challenge_method=S256
  &scope=openid profile email
  &state=XYZ789                      (security token)
```

**What happens:**
1. User sees login page in browser
2. User enters credentials and authorizes
3. Server redirects back to your app with a **code**:

```
http://localhost:3000/auth/callback?code=AUTHORIZATION_CODE_123&state=XYZ789
```

**In your code:**
- Lines 70-80 in `oauth_repository_impl.dart`: Builds the authorization URL
- Lines 112-113: Desktop server captures the callback URL with the code

---

### Step 2: Exchange Code for Access Token

**What you send:**
```
POST https://api.carbonvoice.app/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code
&code=AUTHORIZATION_CODE_123         (from Step 1)
&redirect_uri=http://localhost:3000/auth/callback
&client_id=YOUR_CLIENT_ID
&client_secret=YOUR_CLIENT_SECRET
&code_verifier=SECRET_VERIFIER       (matches the code_challenge from Step 1)
```

**What you get back:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "def50200abc123...",
  "scope": "openid profile email"
}
```

**In your code:**
- Lines 212-219: Builds the token request body
- Lines 223-240: Sends POST request to token endpoint
- Lines 290-305: Parses the response and creates credentials

---

## Visual Flow Diagram

```
┌─────────────┐
│   Your App  │
└──────┬──────┘
       │
       │ 1. Build authorization URL with:
       │    - client_id
       │    - code_challenge (PKCE)
       │    - redirect_uri
       │    - state
       │
       ▼
┌─────────────────────────────┐
│  OAuth Provider Server      │
│  (api.carbonvoice.app)      │
└──────┬──────────────────────┘
       │
       │ 2. User logs in & authorizes
       │
       │ 3. Redirects back with CODE:
       │    http://localhost:3000/auth/callback?code=ABC123&state=XYZ
       │
       ▼
┌─────────────┐
│   Your App  │
│ (Desktop    │
│  Server)    │
└──────┬──────┘
       │
       │ 4. Extract code from callback URL
       │
       │ 5. POST to /oauth/token with:
       │    - code
       │    - code_verifier
       │    - client_id
       │    - client_secret
       │
       ▼
┌─────────────────────────────┐
│  OAuth Provider Server      │
│  (api.carbonvoice.app)      │
└──────┬──────────────────────┘
       │
       │ 6. Returns ACCESS TOKEN
       │
       ▼
┌─────────────┐
│   Your App  │
│  (Now has   │
│   token!)   │
└─────────────┘
```

---

## Why Two Steps?

**Security reasons:**
1. **Authorization code** is short-lived and can only be used once
2. **PKCE (code_verifier)** ensures only your app can exchange the code
3. **State parameter** prevents CSRF attacks
4. The code is sent via browser redirect (visible but temporary)
5. The token exchange happens server-to-server (more secure)

---

## Key Parameters Explained

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `client_id` | Identifies your app | `"abc123xyz"` |
| `client_secret` | Proves you own the client_id | `"secret_key_456"` |
| `code_challenge` | PKCE: Hash of code_verifier | `"E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"` |
| `code_verifier` | PKCE: Secret you keep | `"dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"` |
| `state` | Prevents CSRF attacks | `"random_string_789"` |
| `redirect_uri` | Where to send the code | `"http://localhost:3000/auth/callback"` |
| `scope` | What permissions you want | `"openid profile email"` |

---

## In Your Code

### Step 1: Get Authorization Code
**File:** `lib/features/auth/data/repositories/oauth_repository_impl.dart`

```dart
// Lines 50-53: Generate PKCE codes
final codeVerifier = PKCEGenerator.generateCodeVerifier();
final codeChallenge = PKCEGenerator.generateCodeChallenge(codeVerifier);
final state = PKCEGenerator.generateState();

// Lines 70-80: Build authorization URL
final authUrl = Uri.parse(OAuthConfig.authorizationEndpoint).replace(
  queryParameters: {
    'response_type': 'code',
    'client_id': OAuthConfig.clientId,
    'redirect_uri': redirectUri,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    'scope': OAuthConfig.scopes.join(' '),
    'state': state,
  },
);
```

### Step 2: Exchange Code for Token
**File:** `lib/features/auth/data/repositories/oauth_repository_impl.dart`

```dart
// Lines 212-219: Build token request
final tokenBody = {
  'grant_type': 'authorization_code',
  'code': code,                    // From callback URL
  'redirect_uri': redirectUri,
  'client_id': OAuthConfig.clientId,
  'client_secret': OAuthConfig.clientSecret,
  'code_verifier': codeVerifier,   // Matches code_challenge
};

// Lines 223-240: Send POST request
tokenResponse = await http.post(
  OAuthConfig.tokenEndpointUri,
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: tokenBody,
);

// Lines 290-305: Parse response and create credentials
final tokenJson = jsonDecode(tokenResponse.body);
final credentialsJson = {
  'accessToken': tokenJson['access_token'],
  'tokenType': tokenJson['token_type'] ?? 'Bearer',
  'expiresIn': tokenJson['expires_in'] ?? 3600,
  'scopes': tokenJson['scope']?.split(' ') ?? [],
};
```

---

## Summary

**Simple version:**
1. Send parameters → Get authorization code
2. Send code + secret → Get access token
3. Use access token to make API calls

**Your app flow:**
1. `getAuthorizationUrl()` → Creates URL with all parameters
2. Desktop server opens browser → User authorizes
3. Callback received → Contains `code` parameter
4. `handleAuthorizationResponse()` → Exchanges code for token
5. Token saved → Use it for authenticated API calls

The access token is what you use in the `Authorization: Bearer <token>` header for all subsequent API requests!










