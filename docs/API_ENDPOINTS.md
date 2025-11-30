# API Endpoints Documentation

This document tracks the API endpoints used in the application and their requirements.

## Messages API

### Get Recent Messages
**Endpoint:** `POST /v3/messages/recent`

**Request Body:**
```json
{
  "channel_guid": "string (required)",
  "count": "number (optional, default: 50)",
  "direction": "string (required) - must be 'older' or 'newer'"
}
```

**Response:**
- Status: `201 Created` (or `200 OK`)
- Body: Array of message objects (direct array, not wrapped)

**Message Object Structure (API Format):**
```json
{
  "message_id": "string",
  "creator_id": "string",
  "created_at": "ISO8601 string",
  "last_updated_at": "ISO8601 string",
  "channel_ids": ["string"],  // Array - use first element
  "workspace_ids": ["string"],
  "duration_ms": 12345,  // Milliseconds - convert to seconds
  "is_text_message": false,
  "status": "active",
  "audio_models": [
    {
      "_id": "string",
      "url": "string",  // Audio URL
      "streaming": true,
      "language": "string",
      "duration_ms": 12345,
      "waveform_percentages": [0.0, 0.1, ...],
      "is_original_audio": true,
      "extension": "m3u8" | "mp3"
    }
  ],
  "text_models": [
    {
      "type": "transcript_with_timecode" | "summary",
      "audio_id": "string",
      "language_id": "string",
      "value": "string",  // Transcript or summary text
      "timecodes": [...]
    }
  ]
}
```

**Field Mapping:**
- `message_id` → `id`
- `creator_id` → `userId`
- `channel_ids[0]` → `conversationId` (take first from array)
- `created_at` → `createdAt`
- `audio_models[0].url` → `audioUrl` (extract from first audio model)
- `text_models` (type="transcript_with_timecode").value → `transcript`
- `duration_ms` → `duration` (convert milliseconds to seconds)

**Notes:**
- `channel_guid` uses snake_case (not `channelId`)
- `direction` is required and must be either "older" or "newer"
- For recent messages, use `direction: "newer"` to get the most recent messages first
- API returns `201 Created` for successful POST requests (not just `200 OK`)
- Response is a direct array, not wrapped in an object

### Get Messages (Sequential)
**Endpoint:** `GET /v3/messages/{conversationId}/sequential/{start}/{stop}`

**Parameters:**
- `conversationId`: Channel/conversation ID
- `start`: Starting sequence number (0-based)
- `stop`: Ending sequence number (exclusive)

**Response:**
- Status: `200 OK`
- Body: Array of message objects or `{messages: [...]}` or `{data: [...]}`

### Get Single Message
**Endpoint:** `GET /v5/messages/{messageId}` (fallback to `/v4/messages/{messageId}`)

**Parameters:**
- `messageId`: Message ID

**Response:**
- Status: `200 OK`
- Body: Message object

## Workspaces API

### Get Workspaces
**Endpoint:** `GET /workspaces`

**Response:**
- Status: `200 OK`
- Body: Array of workspace objects or `{workspaces: [...]}` or `{data: [...]}`

**Field Mapping:**
- API returns: `workspace_guid`, `workspace_name`, `workspace_description`
- Normalized to: `id`, `name`, `description`

### Get Single Workspace
**Endpoint:** `GET /workspaces/{workspaceId}`

**Response:**
- Status: `200 OK`
- Body: Workspace object

## Conversations API

### Get Conversations
**Endpoint:** `GET /channels/{workspaceId}`

**Parameters:**
- `workspaceId`: Workspace ID

**Response:**
- Status: `200 OK`
- Body: Array of conversation objects or `{channels: [...]}` or `{data: [...]}`

**Field Mapping:**
- API returns: `channel_guid`, `channel_name`, `workspace_guid`
- Normalized to: `id`, `name`, `workspaceId`

### Get Single Conversation
**Endpoint:** `GET /channel/{conversationId}`

**Response:**
- Status: `200 OK`
- Body: Conversation object

## Users API

**Field Mapping:**
- API may return: `user_guid`, `userId`, `image_url`
- Normalized to: `id`, `avatarUrl`

## Common Patterns

### Field Name Conventions
The API uses snake_case with prefixes:
- `workspace_guid`, `workspace_name`, `workspace_description`
- `channel_guid`, `channel_name`, `channel_description`
- `user_guid`, `image_url`

Our domain models use camelCase:
- `id`, `name`, `description`
- `workspaceId`, `avatarUrl`

The `JsonNormalizer` utility handles this mapping automatically.

### Response Format Variations
The API may return data in different formats:
- Direct array: `[{...}, {...}]`
- Wrapped object: `{messages: [...]}`
- Wrapped object: `{data: [...]}`

All data sources handle these variations.

