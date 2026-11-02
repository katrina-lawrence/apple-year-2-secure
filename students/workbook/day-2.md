
# Day 2 — Secure Architecture and Platform Protections

**Challenge:** Strengthen My Dental Companion by examining how application features interact with iOS platform services, how authentication credentials are protected, and how sensitive AI requests are handled.

Use this workbook to document your investigation, implementation decisions, testing, and reflections. Follow the Day 2 Activity Brief and Student Daily Technical Setup for technical instructions.

## Part 1 — Investigate the Application

Explore the Day 2 starter application and identify how it handles authentication, sensitive information, and communication with external services.

### 1. Authentication and Session Management

Where does the application store authentication or session information?

**File or component:**

**Current approach:**

**Potential security concerns:**

### 2. Hosted AI Communication

Trace how the application prepares and sends requests to the hosted AI service.

**Relevant files or components:**

**What information is transmitted?**

**Where are the trust boundaries?**

### 3. Platform Integration

Identify how the application interacts with iOS features such as Shortcuts, App Intents, and device authentication.

| Feature | Current Implementation | Security Considerations |
|---|---|---|
| App Intents / Shortcuts | | |
| Device authentication | | |
| Session management | | |
| Hosted AI requests | | |

## Part 2 — App Intents and Shortcuts

Investigate and implement the Create Follow-up functionality using App Intents.

### 1. Implementation Record

| File or Component | Change Made | Purpose |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 2. Security Investigation

Consider how the feature is invoked and what happens when it interacts with application data.

What information can the App Intent access?

**Your response:**

What validation or authorization is required?

**Your response:**

Could the feature be invoked when the user is not appropriately authenticated?

**Your response:**

How should the application respond when an action cannot be completed securely?

**Your findings:**

### 3. Testing

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Authorized request | | | |
| Unauthenticated request | | | |
| Invalid or missing input | | | |
| Repeated invocation | | | |

What did your testing reveal?

**Your response:**

## Part 3 — Device Authentication and Secure Storage

Investigate how the application protects sensitive functionality and session credentials.

### 1. Authentication Controls

Identify the functionality that should require additional user verification.

**Selected functionality:**

**Reason for requiring authentication:**

**Authentication mechanism used:**

### 2. Secure Storage

Compare the existing storage approach with your proposed implementation.

| Consideration | Existing Approach | Improved Approach |
|---|---|---|
| Storage location | | |
| Protection of sensitive values | | |
| Access conditions | | |
| Behaviour after application restart | | |
| Error handling | | |

### 3. Implementation Record

Document changes made to protect session information using the appropriate iOS security mechanisms.

**Files or components modified:**

**Changes implemented:**

**Why these changes improve security:**

### 4. Verification

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Save session information | | | |
| Retrieve session information | | | |
| Restart application | | | |
| Sign out or clear session | | | |
| Authentication failure or cancellation | | | |

Were any security or usability trade-offs identified?

**Your response:**

## Part 4 — Backend Integration and Trust Boundaries

Investigate the application's communication with the backend and the hosted AI service.

### 1. Architecture Analysis

Describe the request flow before and after your implementation.

**Original request flow:**

**Updated request flow:**

Which responsibilities should remain within the iOS application?

**Your response:**

Which responsibilities should be handled by the backend?

**Your response:**

### 2. Implementation Record

| Component | Change Made | Security Rationale |
|---|---|---|
| iOS application | | |
| Backend communication | | |
| AI request handling | | |
| Error handling | | |

### 3. Security Considerations

Why might sending hosted AI requests through a backend be preferable to calling the provider directly from the application?

**Your response:**

Which sensitive values or operations should not be exposed in the client application?

**Your response:**

What controls are needed to ensure that backend requests are authorized?

**Your response:**

What information should be excluded from application logs and error messages?

**Your response:**

### 4. Verification

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Successful backend connection | | | |
| Valid authenticated request | | | |
| Invalid or expired session | | | |
| Backend unavailable | | | |
| Hosted AI request | | | |

What security risks remain in the updated architecture?

**Your response:**

## Part 5 — Security Review

Review your implementation across the three areas explored today.

| Area | Security Improvement | Evidence | Remaining Concern |
|---|---|---|---|
| App Intents and Shortcuts | | | |
| Device authentication | | | |
| Secure session storage | | | |
| Backend and AI communication | | | |

Which improvement had the greatest impact on the application's security? Explain your reasoning.

**Your response:**

What additional controls would you recommend for a production environment?

**Your response:**

## Part 6 — Peer Review

Exchange your implementation or findings with another learner or team.

**Reviewer / Team:**

**Areas reviewed:**

**Security concerns identified:**

**Recommendations received:**

**Changes made following the review:**

## Part 7 — Reflection

How did your understanding of trust boundaries change during this challenge?

**Your response:**

What are the limitations of relying exclusively on client-side security controls?

**Your response:**

How do platform security features such as Keychain and device authentication contribute to a broader application security strategy?

**Your response:**

What would you prioritize next if this application were being prepared for production deployment?

**Your response:**

## Evidence Checklist

- [ ] Initial application security investigation documented
- [ ] App Intent implementation and testing recorded
- [ ] Device authentication decisions documented
- [ ] Secure session storage implementation verified
- [ ] Backend and hosted AI request flow analyzed
- [ ] Security improvements supported by test evidence
- [ ] Peer review completed
- [ ] Final reflection completed

---

[Back to Daily Workbooks](README.md)
