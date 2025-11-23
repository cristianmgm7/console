# Localize Hard-Coded Text

You are tasked with migrating hard-coded user-facing text in the Flutter app to the existing `l10n` localization system (`AppLocalizations` and ARB files), while **reusing existing keys whenever possible** to avoid duplicated translations with similar meaning.

The project already uses Flutter's `gen-l10n` with:
- ARB files under `lib/l10n/` (e.g., `app_en.arb`, `app_es.arb`)
- Generated localizations in `lib/l10n/app_localizations.dart`

Your job is to take a given screen or widget file and:
1. Identify all hard-coded user-visible strings.
2. Map each string to an existing localization key when possible.
3. Create new localization keys only when necessary.
4. Update the Dart code to use `AppLocalizations` instead of literals.

---

## Initial Response

When this command is invoked:

- **If one or more file paths are provided as parameters** (e.g., `lib/features/settings/presentation/screens/settings_screen.dart`):
  1. Confirm that you will migrate hard-coded text in those files to the localization system.
  2. List the files you will process.
  3. Begin the migration process described below.

- **If no file path is provided**:
  - Respond with:
    ```
    I can migrate hard-coded user-facing text in a Flutter screen or widget to the localization system.

    Please provide:
    1. The Dart file path(s) to process (e.g., lib/features/settings/presentation/screens/settings_screen.dart)
    2. (Optional) Any feature or domain name I should use as a prefix for new localization keys (e.g., "settings", "home").
    ```
  - Then wait for the user to provide at least one Dart file path.

---

## High-Level Rules

- **User-facing text only**:
  - Migrate only strings that are visible to end users:
    - `Text('...')`
    - `AppBar(title: Text('...'))`
    - Button labels, dialog titles/content, SnackBar messages, form labels, hints, helper texts, error messages, tab labels, section headings, etc.
  - **Do NOT localize**:
    - Log messages (`logger`, `print`, etc.)
    - Exception messages meant only for developers
    - Internal IDs, keys, route names, enum names
    - Test-only strings

- **Prefer reuse of existing keys**:
  - Before creating any new key, you **must** search the existing ARB base locale (`lib/l10n/app_en.arb`) for:
    - An **exact match** of the string value.
    - A **close semantic match** (same meaning, even if slightly different wording or punctuation).
  - If a suitable key exists, **reuse that key** instead of creating a new one.

- **New keys must be clear and consistent**:
  - Use lowerCamelCase.
  - Group by feature or context when possible (e.g., `settingsAppTitle`, `settingsNotificationsSectionTitle`, `homeWelcomeMessage`).
  - Provide a concise but clear description for each new key in the base ARB file.

- **Never break behavior**:
  - The UI must look and behave the same, except now the text is driven by localization.
  - Do not change business logic or side effects when migrating strings.

---

## File Handling Steps (Per Dart File)

For each Dart file you are given:

1. **Read the file fully** using the Read tool (no offset/limit).
2. **Scan for hard-coded user-facing strings**, including but not limited to:
   - `Text('...')`, `Text("...")`
   - `AppBar(title: Text('...'))`
   - `ElevatedButton`, `TextButton`, `OutlinedButton`, `IconButton` labels
   - `SnackBar`, `AlertDialog`, `showDialog`, `BottomSheet` titles and content
   - `InputDecoration(labelText: '...')`, `hintText`, `helperText`, `errorText`
   - Tab labels, section headers, empty-state messages, placeholders.
3. Create a **temporary list** of all candidate strings with:
   - The literal text
   - Where it appears (widget / property / line number)
4. For each candidate, follow the **Localization Process** below.

---

## Localization Process (Per String)

### 1. Check for Existing Keys (Avoid Duplicates)

Use the base ARB file `/Users/cristian/Documents/tech/kairos/lib/l10n/app_en.arb` as the source of truth for existing keys and their English values.

For each candidate string:

1. **Normalize the string** for matching:
   - Trim leading/trailing whitespace.
   - Compare case-insensitively.
   - Ignore trailing punctuation when searching (e.g., `'Error'` vs `'Error.'`).
2. **Search for exact matches** in `app_en.arb`:
   - If there is a key where the value exactly matches (ignoring case and trivial whitespace), **reuse this key**.
3. **Search for close semantic matches**:
   - Look for strings that are:
     - Very similar text (e.g., `'App Settings'` vs `'Settings'`, `'Delete'` vs `'Delete item'` if used in the same context).
     - Clearly representing the same concept (e.g., a generic "Error" message).
   - If a close match exists and using it would **not change the meaning** for users, prefer reusing it.
4. **Only if no suitable key exists**, create a **new key**:
   - Choose a descriptive name, optionally prefixed by feature (e.g., `settingsAppSettingsTitle`, `journalEmptyStateMessage`).
   - Ensure the name does **not conflict** with any existing key.

### 2. Add or Reuse the Key in `app_en.arb`

- **If reusing an existing key**:
  - Note the key name and do **not** modify the ARB file for this key.

- **If creating a new key**:
  - Edit `/Users/cristian/Documents/tech/kairos/lib/l10n/app_en.arb` to add:
    ```jsonc
    "newKeyName": "Exact English text from the UI",
    "@newKeyName": {
      "description": "Clear description of where/how this text is used"
    }
    ```
  - Maintain proper JSON syntax (commas between entries).
  - Place the new key near related keys if possible (e.g., other settings-related keys).

### 3. Ensure Other Locales Are Updated

For each new key:

- Open `/Users/cristian/Documents/tech/kairos/lib/l10n/app_es.arb` (and any other ARB locale files if they exist).
- Add the same key with an appropriate translation:
  ```json
  "newKeyName": "Translated text"
  ```
- If you **cannot** confidently provide the translation:
  - Temporarily copy the English value.
  - Add a short `// TODO: translate` comment in your explanation to the user so they can review later.

### 4. Regenerate Localization Classes

Once ARB updates are complete (or at least after a batch of changes):

- From the project root (`/Users/cristian/Documents/tech/kairos`), run:
  ```bash
  flutter gen-l10n
  ```
  or rely on `flutter run` / `flutter test` to regenerate if that is the existing workflow.
- This ensures `app_localizations.dart` and the language-specific classes are updated with new getters.

---

## Updating Dart Code to Use `AppLocalizations`

For each Dart file being migrated:

1. **Import localizations if not already imported**:
   ```dart
   import 'package:kairos/l10n/app_localizations.dart';
   ```

2. **Obtain the localization instance** within `build` (or any method with a `BuildContext`):
   ```dart
   final l10n = AppLocalizations.of(context)!;
   ```
   - Prefer defining this once near the top of the `build` method and reusing it.
   - If the file already uses `AppLocalizations.of(context)`, follow the existing style (either `l10n` variable or direct calls).

3. **Replace hard-coded strings**:
   - Example transformations:
     - `Text('Settings')` → `Text(l10n.settings)`
     - `title: const Text('App Settings')` → `title: Text(l10n.settingsAppSettingsTitle)`
     - `SnackBar(content: Text('Error saving'))` → `SnackBar(content: Text(l10n.errorSaving))`
     - `InputDecoration(labelText: 'Email')` → `InputDecoration(labelText: l10n.emailLabel)`
   - Remove `const` from widgets when replacing a literal with a localization getter (because the value is no longer compile-time constant).

4. **Non-UI layers (no BuildContext available)**:
   - Prefer keeping localization at the UI layer:
     - Pass already-localized strings down into controllers/services, **or**
     - Pass an `AppLocalizations` instance from the widget into a lower-level class that needs it.
   - Do **not** try to access `BuildContext` in places where it does not naturally exist.

---

## Verification

After updating ARB files and Dart code:

1. **Run the app or tests**:
   - Use `flutter run` or existing project commands.
   - Ensure there are no compilation errors (missing getters, import issues).
2. **Visually verify the screen(s)**:
   - Confirm all previous hard-coded strings now display correctly through localization.
   - Switch the app language (e.g., between English and Spanish) and verify that:
     - All newly localized strings change appropriately.
     - There are no remaining obvious hard-coded UI strings on the processed screen.
3. **Check for unintended changes**:
   - Ensure formatting, punctuation, and capitalization are as expected.
   - Confirm that behavior and layout are unchanged.

---

## Communication Protocol

When you finish processing a file or set of files, respond using this format:

```
Localization Migration Complete

Processed files:
- lib/features/settings/presentation/screens/settings_screen.dart
- [any other files]

Reused keys:
- settings → l10n.settings
- logout → l10n.logout

New keys added:
- settingsAppSettingsTitle: "App Settings"
  - Added to app_en.arb with description
  - Added to app_es.arb with translation "Ajustes de la aplicación"

Behavior:
- All user-facing strings on the processed screens now come from AppLocalizations.
- No functional changes other than localization.
```

If you encounter ambiguity when choosing between reusing an existing key or creating a new one, explain the options and ask the user which they prefer before proceeding. 




