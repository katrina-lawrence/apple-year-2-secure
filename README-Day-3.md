# Day 3: Note Classifier (Starter)

## Goal
Implement a classifier that can classify a note. The current implementation is a stub and returns placeholder data.

## Getting Started
- Start at `Dental Notes/ContentView.swift` in:
  - `private func classifyNote()` (currently wires classification to stubbed output)
  - `private func generateClassificationStub(for noteText: String) -> NoteClassificationResult` (currently returns placeholder scores)
- Review where note data is created or passed into the classifier flow.
- Replace placeholder behavior with real classification logic.
- Connect the classifier output back into the app flow where results are displayed or consumed.
- Keep your implementation modular so it can be refined as requirements are finalized.

## Notes for Learners
- Start with a simple, end-to-end working path before adding improvements.
- Add lightweight checks/tests to verify placeholder output is no longer returned.
- Document assumptions in code comments or notes, since implementation details are still evolving.

## Backend Endpoint Configuration
Make sure the app is configured to use the correct backend server endpoint for your environment (for example, local development vs. shared/staging). Verify that classifier-related requests are sent to the expected server before debugging classifier logic.
