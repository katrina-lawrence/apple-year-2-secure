# Day 2: Build a follow-up intent, then secure the app

Start with the setup in [README.md](README.md). Use a test account and made-up dental notes.

## What is provided

| Part | Starting point |
| --- | --- |
| Login and data | Working backend login, notes and follow-ups. `SessionTokenStore.swift` saves the access and refresh tokens in UserDefaults. |
| Hosted AI | `HostedAIClient.swift` sends a real Anthropic request using the key in `LabAIConfig.swift`. Replace the placeholder locally to run it. |
| App Intent | `FollowupAppIntents.swift` registers Create Dental Follow-up in Shortcuts/Siri. Its `perform()` method contains TODOs and currently returns "Follow-up creation is not implemented yet." It creates no record. |

## Build the intent

Complete `CreateDentalFollowupIntent.perform()`:

1. Trim `descriptionText` and reject an empty description or more than 2,048 characters. This matches the app editor and backend limit.
2. Use `FollowupIntentSupport.makeContext()` for the temporary SwiftData context and create an `AppSessionViewModel`. It loads the signed-in account's tokens.
3. Call `createFollowupAndReturnID(noteID:type:descriptionText:modelContext:)`. Use `nil` for `noteID`, `"Custom"` for `type`, and the validated description.
4. Handle a missing session or a failed creation. Return a success dialog only when the backend returns a created record ID.
5. Run **Create Follow-up** from Shortcuts. For Siri, use "Create a dental follow-up in My Dental Companion" and provide the description when asked. Return to the app and pull to refresh the Follow-ups list to check the saved record.

The current follow-up model has no due-date field. Use the description for this activity.

Leave device authentication at its default for this first working version. The server must still require a valid account token. The security task below checks whether someone holding a locked phone can act through that signed-in account.

## Security task 1: Protect the intent

Run this investigation before replacing UserDefaults with Keychain. A Keychain item that cannot be read while locked can hide the missing intent policy.

1. Sign into the test account and confirm creation works while unlocked.
2. On a passcode-protected iPhone, allow Siri while locked, then lock it and run the same intent. Avoid unintentionally unlocking it with Face ID. Record any unlock request and check whether a new follow-up appears. Record the device and settings if the system blocks the attempt before the intent runs.
3. Update the intent so creating a private follow-up requires authentication on the device running it. Keep the backend's account and record access checks.
4. Repeat the test. Completing authentication should allow the action; cancelling or failing authentication must create no follow-up. Normal unlocked use should still work. Do not expect a new biometric prompt on every call from an already unlocked device.

Useful reference: [AppIntent authenticationPolicy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy).

## Security task 2: Move the session tokens

Find the login, refresh, startup and logout calls to `SessionTokenStore.shared` in `ServerMode.swift`. The starter uses `day2.session.accessToken` and `day2.session.refreshToken` in UserDefaults.

Replace that storage with Keychain. For existing sessions, save and verify the Keychain copies before deleting the UserDefaults values. Handle a failed save without claiming the migration succeeded or losing the existing session.

Check login, relaunch, token refresh and logout. Verify the old preference entries are gone after a successful migration. Use a controlled failed-write test to check that the old tokens are retained when migration fails. Run the intent tests again after the storage change.

## Security task 3: Move the provider key

The starter's **Process Note** action calls `HostedAIClient.processNote(...)` directly. Locate the API key in `LabAIConfig.swift` and the `x-api-key` header in `HostedAIClient.swift`.

1. Configure the local backend with `AI_ENDPOINT`, `AI_MODEL` and `AI_API_KEY` using the backend README, then restart it. Use the same provider model and prompts when comparing results.
2. In `ContentView.swift`, replace the direct provider call with the existing `session.processNote(noteID: note.id)` call. The backend accepts the note ID, checks the signed-in account owns it, and calls the provider.
3. Remove the client provider key and the direct provider client/configuration from the app. The provider key belongs on the backend; it is not another session token to move into the phone's Keychain.
4. Rebuild and process a made-up note. Check that the result can still be reviewed and saved, and that the built app contains no provider key. A request without valid backend authentication must be rejected.

Changing the URL alone is insufficient: the backend accepts a note ID and returns processed fields, while Anthropic accepts messages and returns content blocks.

Reference: [Anthropic API requests](https://platform.claude.com/docs/en/api/overview). The starter defaults to [Claude Haiku 4.5](https://platform.claude.com/docs/en/models/haiku-4-5/overview); check the classroom model before the session.

## Record your results

For each of the three fixes, record the code changed, the test performed, the actual result and any case you could not test. Include a normal case and a denied or failure case. Keep real tokens and keys out of screenshots and shared code.

ATS is covered on Day 4.
