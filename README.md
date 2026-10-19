# My Dental Companion

## Third-party AI Local Configuration

The app can optionally load third-party AI settings from `Dental Notes/ThirdPartyAIConfig.plist`.

1. Copy `Dental Notes/ThirdPartyAIConfig.example.plist` to `Dental Notes/ThirdPartyAIConfig.plist`.
2. Replace placeholder values with your local development endpoint, model, and API key.
3. Run the app.

When `Third-party provider` is selected in Settings, endpoint/model/API key are read from this plist only.

Security notes:
- `Dental Notes/ThirdPartyAIConfig.plist` is gitignored and should stay local-only.
- `Dental Notes/ThirdPartyAIConfig.example.plist` is safe to commit because it contains placeholders only.
- Do not commit real secrets.

## Backend Server Mode Configuration

To run the app in server mode:

1. Copy `Dental Notes/BackendConfig.example.plist` to `Dental Notes/BackendConfig.plist`.
2. Set `baseURL` to your backend URL (HTTP and HTTPS are supported).
3. Build with the `SERVER_MODE` Swift compilation condition enabled.

Notes:
- In builds without `SERVER_MODE`, the app runs in local-only mode.
- `Dental Notes/BackendConfig.plist` is gitignored.
- In builds with `SERVER_MODE`, notes and followups are stored in an in-memory SwiftData store only (no persistent on-device SwiftData files).
- In builds with `SERVER_MODE`, selecting `Third-party provider` routes note processing to backend `POST /notes/process` using the note ID. The app does not use `ThirdPartyAIConfig.plist` for that path.
