
# Day 4

## Activity 1 — On-Device AI: Build, Test & Evaluate

*Learner activity workbook*  
*Build & Test: 70 minutes*  
*Security evaluation: 55 minutes (details beyond the stated focus are pending the evaluation slides)*  
*Starting branch: `main`*

## Activity Overview

Complete an on-device structured-generation feature in the supplied application. Use the existing review and editing flow, test how it behaves under normal and failure conditions, and keep evidence of what actually happened.

The subsequent security evaluation focuses on generated-summary rendering and App Transport Security (ATS).

### What You Should Deliver

| Area | Required Outcome |
|---|---|
| Implement | Complete `generateAppleDraft()` and add `@Generable` to the three supplied draft types. |
| Adapt | Use the supplied prompt templates and schema for the supplied notes. |
| Integrate | Retain the existing review flow, including manual editing before saving. |
| Test | Compare useful outputs, uncertainty, cancellation and failure behaviour. |
| Record | Keep the input, starting state, expected result, actual result and observed saved data. |

**Working arrangement:** Use a shared pair workspace, but each learner keeps a short individual test record. Use the supplied test notes and approved test account.

## Build & Test

| Checkpoint | Time | Team Work | Support Focus |
|---|---|---|---|
| 1. Working starting point | 10 min | Run the starter, locate the TODO and record baseline behaviour. | Xcode, application and backend |
| 2. Structured generation | 25 min | Adapt the prompts/schema and complete generation. | AI behaviour and Swift integration |
| 3. Application handles the result | 20 min | Integrate review, availability and errors. | Application flow |
| 4. Feature tests | 15 min | Run normal and failure cases; document outcomes. | Both instructors |

*The checkpoint overview is included in the first 10 minutes; it does not add time.*

### Checkpoint 1 — Working Starting Point

1. Launch the **server-mode starter** and sign in to the test account.
2. Locate the Apple-generation TODO in `ContentView.swift`, the supplied prompt files, and **Settings > Security Demos > ATS Demo**.
3. Record model readiness and the current `appleIntelligenceNotImplemented` result.
4. Identify the files and starting lines you will edit.

**Expected baseline:** `FoundationModels` is already imported, and readiness and error handling are provided. A "feature not implemented" result is a baseline, **not** a completed AI feature.

#### Checkpoint Record

| Item | Your Observation |
|---|---|
| Device / OS and application version | |
| Test account / starting state (no passwords or tokens) | |
| Model readiness | |
| Baseline result or error | |
| TODO and prompt file locations | |

### Checkpoint 2 — Useful Structured Generation

1. Add `@Generable` to the three supplied draft types.
2. Complete the `generateAppleDraft()` session call so it returns the typed `AIProcessedNoteDraft`.
3. Render and use `PromptSystem.md` and `PromptUser.md` through `AIPromptTemplateLoader`.
4. Compare results for a normal note, missing information and uncertain timing.
5. Keep unknown values unknown: do not invent an amount or turn tentative wording into a confirmed appointment date.

**Expected behaviour:** The typed generation produces a useful draft when available; missing facts remain absent or unknown. Unavailable generation or errors are reported accurately rather than shown as successful output.

### Checkpoint 3 — Application Handles the Result

Show generated fields in the existing review screen before saving.

1. Preserve manual editing and the supplied availability and error handling.
2. Handle unavailable generation, thrown errors and repeated taps on **Process Note**.
3. Confirm that **Cancel** leaves stored data unchanged.
4. Confirm that an approved **Save** updates only the intended note.

**Boundary for this checkpoint:** This verifies the feature flow. The starter's `GeneratedSummaryHTMLView` rendering is addressed in the later security evaluation, not treated as fixed during the feature build.

### Checkpoint 4 — Feature Tests

Run the following cases and record what actually happened. Do not mark a case as passed based on code review alone.

| Test Case | Expected Behaviour | Actual Result | Pass / Fail / Not Run |
|---|---|---|---|
| Normal multi-part note | Useful draft; intended values appear only after approval and Save. | | |
| Missing or uncertain information | No invented amount or confirmed appointment date. | | |
| Cancel in the review screen | No stored changes. | | |
| Model unavailable or generation fails | Clear outcome; original records remain available. | | |
| Repeated Process Note taps | No overlapping request or unintended duplicate save. | | |

For each test, record the input, starting state, expected result, actual result, device/OS and code version.

A clear reproducible record is sufficient; a screenshot is not required when the result can be documented and reproduced.

#### Individual Test Record Template

Copy one row per case or use a separate record for complex failures.

| Test ID | Input / Scenario | Starting State | Expected Result | Actual Result | Saved-Data Observation | Device / OS / Version | Status |
|---|---|---|---|---|---|---|---|
| D4-01 | | | | | | | |
| D4-02 | | | | | | | |
| D4-03 | | | | | | | |

---

## Security Evaluation

*Duration: 55 minutes*

**Focus identified in the supplied slides:** Fix and evaluate generated-summary rendering and App Transport Security (ATS) after the 70-minute feature build.

The detailed evaluation procedure, timing breakdown, test cases and expected security outcomes have not yet been supplied. This section is therefore a recording framework, not a substitute for the remaining evaluation instructions.

### Evaluation Evidence Record

| Area | Starting Behaviour / Risk Observed | Change or Control Tested | Test Input and Method | Actual Result | Remaining Limitation / Next Action |
|---|---|---|---|---|---|
| Generated-summary rendering | | | | | |
| App Transport Security (ATS) | | | | | |

### Evaluation Questions

- What did the application do **before** the security change?
- What changed in the implementation or configuration?
- Which observed test result supports the claimed improvement?
- What does that evidence **not** establish?
- Which test failed, could not run, or still needs to be completed?

**Important:** Do not assume a test passed if it was unavailable. Record the limitation and any follow-up needed.
