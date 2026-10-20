# Day 4: Implement Note Processing with Apple Intelligence

The Apple Intelligence note-processing path is currently stubbed and returns placeholder data.

## Where to implement

- File: `Dental Notes/ContentView.swift`
- Function: `NoteFollowupAIService.processNoteWithApple(noteText:referenceDate:)`

## What to do

- Replace the TODO stub in `processNoteWithApple(noteText:referenceDate:)` with a real Apple Intelligence implementation.
- Build the prompt from the note text and reference date.
- Run on-device model inference and decode into `AIProcessedNoteDraft`.
- Return the parsed draft so `normalizeProcessedResult(from:)` can map it into `ProcessedNoteResult`.
- Keep safe fallbacks for empty notes and parsing/model failures.

