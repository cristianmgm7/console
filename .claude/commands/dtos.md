You are given a raw JSON example representing a Message object.
Your job is to create:
	1.	Clean DTO classes that perfectly mirror the JSON structure exactly as the API returns it.
	2.	Clean domain models that represent only the fields that are meaningful for the app’s logic.
	3.	Mappers (toDomain()) from DTO → domain.

Rules:
• The DTOs must include all JSON fields, even if they are not used in the domain.
• Nested maps and lists must each become their own DTO class (e.g., audio_models, text_models, reaction_summary, utm_data).
• Domain models must only include fields that are relevant for app features (audio tracks, transcript text, timestamps, ids, creator info, duration, etc.).
• Domain entities must be simpler than DTOs — no backend noise or unused metadata.
• Mappers must never lose required data for the domain.
• Do NOT normalize or restructure the domain unless the JSON forces it.
• Use nullable fields where the JSON allows null.
• Output only Dart code.

Here is the JSON example you must use to infer all DTOs and domain models: