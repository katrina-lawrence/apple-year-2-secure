# Day 2: Implement an AppIntent to Create a New Followup

## Goal
Today you will add an `AppIntent` that sends a request to your backend to create a new follow-up.

## Getting Started
1. Create a new `AppIntent` type (for example: `CreateFollowupIntent`).
2. Add intent parameters for the data needed to create a follow-up (for example: title, notes, due date).
3. Implement `perform()` and call your networking layer from inside it.
4. Build the request payload from the intent parameters.
5. Send a `POST` request to your backend endpoint for creating follow-ups.
6. Handle success and failure cases and return an appropriate `IntentResult`.
7. Test the intent from Shortcuts/Siri and verify the follow-up is created.

## Backend Endpoint Note
Make sure your app points to the correct backend server base URL for your environment (local, staging, or production). Keep the endpoint configurable (for example, via build settings or a config file) so learners can switch environments without changing intent logic.
