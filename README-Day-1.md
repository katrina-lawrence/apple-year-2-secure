# Day 1: Implement Hosted AI Note Processing

This exercise guides you through implementing the hosted AI provider call that turns a raw note into a processed draft.

## Start Here

Begin in:
- `Dental Notes/ContentView.swift`
- Function: `processNoteWithThirdParty(...)`

This is the main entry point for the third-party hosted provider flow.

## Configure Third-Party Settings

Before coding, set up local provider config:
1. Copy `Dental Notes/ThirdPartyAIConfig.example.plist` to `Dental Notes/ThirdPartyAIConfig.plist`.
2. Fill in endpoint, model, and API key values.
3. Keep `ThirdPartyAIConfig.plist` local only (do not commit real secrets).

## What You Should Implement

1. Read the function inputs and return type in `processNoteWithThirdParty(...)`.
2. Build the hosted provider request from the note and prompt context.
3. Send the request to the configured endpoint.
4. Parse the provider response into the draft output expected by the app.
5. Handle failures safely (network errors, bad responses, empty output).

## Suggested Work Flow

1. Find where `processNoteWithThirdParty(...)` is called and confirm expected behavior.
2. Use `ThirdPartyAIConfig.plist` values for endpoint/model/key configuration.
3. Implement the network call and response parsing inside `processNoteWithThirdParty(...)`.
4. Return a user-safe error when the provider call fails.

## Verify Your Work

1. Run the app and select the third-party provider.
2. Enter a sample note and process it.
3. Confirm a draft is returned and rendered correctly.
4. Temporarily break config (for example, invalid key) and confirm graceful failure handling.

## Done Criteria

You are done when note processing with the third-party provider:
- Produces a valid draft on success.
- Surfaces clear, safe failures on error.
- Keeps implementation centered in `processNoteWithThirdParty(...)` in `Dental Notes/ContentView.swift`.
