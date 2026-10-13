# My Dental Companion

## Third-party AI Local Configuration

The app can optionally load third-party AI settings from `Dental Notes/ThirdPartyAIConfig.plist`.

1. Copy `Dental Notes/ThirdPartyAIConfig.example.plist` to `Dental Notes/ThirdPartyAIConfig.plist`.
2. Replace placeholder values with your local development endpoint, model, and API key.
3. Run the app.

Security notes:
- `Dental Notes/ThirdPartyAIConfig.plist` is gitignored and should stay local-only.
- `Dental Notes/ThirdPartyAIConfig.example.plist` is safe to commit because it contains placeholders only.
- Do not commit real secrets.
