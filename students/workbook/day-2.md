
# Day 2 — Siri/Shortcuts Integration & Security

## Activity 1 — Extend Your Data-Flow and Threat Map

*Duration: 5 minutes*  
*Format: Individual activity and pair discussion*

My Dental Companion now supports an additional interaction through Siri and Apple Shortcuts, allowing users to initiate an application action without opening the app directly. This introduces a new path for accessing and modifying dental information.

### Your Task

Return to the data-flow and threat map you created on Day 1.

1. **Add the Siri/Shortcuts workflow** to your existing diagram.
2. **Trace the flow:** Show how a Siri/Shortcuts intent reaches the application, calls the shared create method, communicates with the backend, and returns a result.
3. **Identify sensitive information:** Mark where dental information and the account token travel through the system.
4. **Identify the access-control checkpoint:** Indicate where the backend should verify whether the request is authorized.
5. **Predict a security risk:** Identify one way the new Siri/Shortcuts integration could expose or modify information without appropriate safeguards.

### Compare with a Partner

Discuss your diagrams and compare the security risks you identified.

**Keep your updated map.** You will revisit it as you test and improve the Siri/Shortcuts integration.

### Your Observations

**Where should access be verified?**

**Your response:**

**What security risk did you identify?**

**Your response:**

---

## Activity 2 — My Dental Companion: Siri/Shortcuts Integration & Security

*Duration: 90 minutes*  
*Format: Hands-on technical challenge*  
*Application: My Dental Companion*  
*Starting branch: `main`*

### Activity Overview

Extend My Dental Companion with a Siri/Shortcuts feature that allows a signed-in user to create a dental follow-up.

Once the feature works, investigate and address three security vulnerabilities:

- **Intent access bypass:** The intent may run without appropriate device authentication.
- **Insecure token storage:** Session tokens are stored in `UserDefaults`.
- **Exposed provider credentials:** The application contains a client-side AI provider key.

Your goal is to deliver a working feature while implementing and verifying all three security improvements.

---

### Stage 1 — Complete the Feature and Establish a Baseline

Complete the **Create Follow-up App Intent**.

Your implementation must:

- Create one follow-up for the signed-in account.
- Trim the description and accept between 1 and 2,048 characters.
- Reject blank or oversized descriptions.
- Return an accurate result for successful, failed, or uncertain saves.
- Preserve backend account and record-ownership checks.

A due-date field is not required.

#### Baseline Testing

Before implementing the security improvements, test the current behaviour and record your observations.

| Security area | What did you test? | Observed behaviour |
|---|---|---|
| Intent access | Can the intent run without the required device authentication? | |
| Session-token storage | Where are the access and refresh tokens stored? | |
| Provider credentials | Can the AI provider credential or direct API client be found in the application? | |

---

### Stage 2 — Implement Three Security Improvements

| Vulnerability | Required improvement |
|---|---|
| Intent access bypass | Require local device authentication before follow-up creation. Retain backend account and ownership checks. |
| Tokens in `UserDefaults` | Migrate both session tokens to Keychain. Remove the previous `UserDefaults` storage. |
| Provider key in the application | Use `session.processNote(noteID:)` to route AI processing through the backend. Remove the client-side provider key and direct AI client. |

#### Implementation Record

| Security improvement | What did you change? | Files/components modified |
|---|---|---|
| Device authentication | | |
| Keychain storage | | |
| Backend AI processing | | |

---

### Stage 3 — Retest Your Implementation

Run the following tests and record the actual results.

| Test case | Expected protected behaviour | Actual result | Pass / Fail / Not Run |
|---|---|---|---|
| Valid description, signed-in account | Exactly one follow-up is created. | | |
| Device locked, authentication completed | Authentication occurs before creation; one follow-up is created. | | |
| Required device authentication cancelled | No follow-up is created; no success is reported. | | |
| Blank description or 2,049 characters | Clear error; no record saved. | | |
| Request fails or response is lost | No false success; check whether the server saved before retrying. | | |
| Invalid session or another account's record | Unauthorized access is rejected. | | |
| Login, relaunch, refresh and logout | Session lifecycle continues to work. | | |
| Session-token storage | Both tokens are absent from `UserDefaults`. | | |
| Hosted AI processing | Backend AI works without a bundled provider key. | | |
| Unauthorized backend AI request | Request is rejected. | | |

**Important:** Record tests that fail or cannot be completed. An unavailable device, backend, or API does not count as a successful test.

---

### Security Evaluation & Peer Review

Exchange implementations and evidence with another team.

#### Part A — Review the Security Evidence

| Security control | Evidence to verify | What the evidence does not prove |
|---|---|---|
| Intent access | Authorized creation works; cancelled authentication creates nothing. | Device authentication does not establish server-side record ownership. |
| Keychain | Login, relaunch, refresh and logout work; old token entries are absent. | An authorized running application can still retrieve its tokens. |
| Provider credentials | No client-side key; backend AI works; unauthorized requests fail. | Backend permissions, rate limits and monitoring still require validation. |

#### Part B — Review Another Team's Decision

Select at least one security improvement implemented by another team.

**Protection reviewed:**

#### 1. Reproduce

Run one permitted case and one denied or failure case.

| Test | Expected result | Actual result |
|---|---|---|
| Permitted case | | |
| Denied or failure case | | |

#### 2. Explain

What vulnerability does the code change address?

**Your response:**

#### 3. Challenge

What path, state, or assumption has not been covered by the evidence?

**Your response:**

#### 4. Record Your Finding

Complete the following statements:

**The permitted case produced:**

**The denied or failure case produced:**

**This supports the security improvement because:**

**The evidence does not yet establish:**

**Our recommended next test or action is:**

---

### Update Your Threat Map

Return to the threat map you started earlier in Day 2.

Update it to show the application architecture after your security improvements.

#### Required Updates

| Element | What to include |
|---|---|
| Entry points | Application UI and Siri/Shortcuts App Intent |
| Sensitive assets | Dental notes, follow-ups, session tokens and provider credentials |
| Trust boundaries | System input, application operation, secure storage and backend |
| Device access | Authentication at the intent entry point |
| Session management | Access and refresh tokens stored in Keychain |
| Backend authorization | Account and record-ownership checks |
| Hosted AI | Backend communication with the external AI provider |

#### Architecture Sketch

Draw your updated architecture below or attach a diagram.

Include the following paths:

- **Follow-up creation:** Siri/Shortcuts → App Intent → Device Authentication → Application Operation → Backend Authorization → Saved Follow-up
- **Session management:** Application ↔ Keychain
- **Hosted AI:** Application → Backend → External AI Provider → Backend → Application

Mark where each security control operates and identify the remaining trust boundaries.

**Your diagram:**

---

### Remaining Risks

Identify at least one risk or missing test that your implementation does not resolve.

| Remaining risk or missing test | Potential impact | Recommended next action | Owner |
|---|---|---|---|
| | | | |
| | | | |

---

### Final Reflection

#### Question 1

Which security improvement had the greatest impact on the application's architecture? Why?

**Your response:**

#### Question 2

Which test provided the strongest evidence that a vulnerability was addressed?

**Your response:**

#### Question 3

What security risk remains even after all three improvements?

**Your response:**

#### Question 4

What would you prioritize before deploying this feature in a production environment?

**Your response:**


### Resources
https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy
https://developer.apple.com/documentation/localauthentication/logging-a-user-into-your-app-with-face-id-or-touch-id
https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility
https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave
https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files

