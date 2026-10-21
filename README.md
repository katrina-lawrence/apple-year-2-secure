# My Dental Companion

See [README-Day-1.md](README-Day-1.md) for the hosted AI build activity and prompt-injection exercise.

`Dental Notes/PromptSystem.md` deliberately contains a fake `ANTHROPIC_API_KEY` GUID for that exercise. It is not a working key and must never be replaced with a real credential. The starter loads the template; students complete the hosted provider call before testing it.

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
