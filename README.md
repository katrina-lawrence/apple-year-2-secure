# My Dental Companion

## Third-party AI Local Configuration

In local-only builds, selecting `Third-party provider` now uses a deterministic in-app stub and does not call any external AI API directly.

The app still includes third-party configuration scaffolding at `Dental Notes/ThirdPartyAIConfig.plist` for learner exercises.

1. Copy `Dental Notes/ThirdPartyAIConfig.example.plist` to `Dental Notes/ThirdPartyAIConfig.plist`.
2. Replace placeholder values with your local development endpoint, model, and API key when implementing the learner exercise.
3. Run the app.

When `Third-party provider` is selected in Settings in local mode, note processing is stubbed.

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
