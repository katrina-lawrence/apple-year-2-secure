
# Day 4 — On-Device AI and Application Security

**Challenge:** Investigate how on-device AI changes application architecture, data handling, and security responsibilities. Explore how My Dental Companion processes generated content, identify vulnerabilities associated with unsafe HTML rendering and network communication, and implement appropriate security improvements.

Use this workbook to document your investigation, implementation decisions, testing, and reflections. Follow the Day 4 Activity Brief and Student Daily Technical Setup for technical instructions.

## Part 1 — Investigate the Application

Explore the Day 4 starter application and examine how it processes dental notes, communicates with the backend, and displays content.

### 1. Application Architecture

Identify the components involved in processing and displaying dental notes.

| Component or File | Responsibility | Security Considerations |
|---|---|---|
| | | |
| | | |
| | | |
| | | |
| | | |

### 2. Data Flow Investigation

Trace how information moves through the application.

**Where does the application obtain the note content?**

**How is the content processed?**

**Where is the content displayed?**

**Which components communicate with the backend?**

### 3. Initial Security Assessment

Which components handle potentially sensitive information?

**Your findings:**

Where does the application cross a trust boundary?

**Your findings:**

What risks could arise if the application treats externally supplied or generated content as trusted?

**Your analysis:**

## Part 2 — On-Device AI with Foundation Models

Investigate the use of Apple's on-device Foundation Models framework for processing dental note content.

### 1. Implementation Investigation

Identify where the application invokes or is expected to invoke the on-device model.

**Relevant files or components:**

**Input provided to the model:**

**Expected model output:**

**How the output is used by the application:**

### 2. Implementation Record

Document the changes made to support the planned on-device AI functionality.

| File or Component | Change Made | Purpose |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 3. Functional Testing

Use fictional dental information to test the functionality.

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Standard dental note | | | |
| Incomplete note | | | |
| Ambiguous information | | | |
| Unexpected or unsupported input | | | |
| Model unavailable | | | |

### 4. Evaluate the Results

How accurately did the generated output reflect the original note?

**Your analysis:**

Did the model introduce information that was not present in the input?

**Your observations:**

How should the application handle incomplete, incorrect, or unsupported generated content?

**Your recommendation:**

What should happen if the on-device model is unavailable?

**Your recommendation:**

## Part 3 — Privacy and On-Device Processing

Compare on-device AI processing with the hosted AI approach explored earlier in the program.

### 1. Architecture Comparison

| Consideration | Hosted AI Processing | On-Device AI Processing |
|---|---|---|
| Where processing occurs | | |
| Data transmission | | |
| Network dependency | | |
| Privacy considerations | | |
| Model availability | | |
| Security responsibilities | | |

### 2. Security Analysis

What privacy advantages can on-device processing provide?

**Your analysis:**

Which security risks remain even when data is processed locally?

**Your analysis:**

How might model availability, device compatibility, or operating system requirements affect the application's design?

**Your analysis:**

Would on-device processing eliminate the need for backend security controls? Explain your reasoning.

**Your response:**

## Part 4 — Investigate Unsafe HTML Rendering

Examine how the application displays content that may contain HTML or other markup.

### 1. Identify the Rendering Process

**Relevant file or component:**

**Source of the displayed content:**

**How the content is rendered:**

**What assumptions does the application make about the content?**

### 2. Vulnerability Investigation

Using the approved test content, investigate whether untrusted markup can affect the application's behaviour.

| Test | Input or Scenario | Observed Behaviour | Security Concern |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |

### 3. Analyze the Findings

What makes the rendering approach potentially unsafe?

**Your analysis:**

How could untrusted or AI-generated content introduce a security vulnerability?

**Your analysis:**

What is the difference between displaying content as text and interpreting it as executable or active markup?

**Your analysis:**

What could be the consequences of unsafe rendering in an application that processes sensitive information?

**Your analysis:**

## Part 5 — Implement and Verify Rendering Improvements

Identify and implement an appropriate approach to handling untrusted content.

### 1. Mitigation Plan

**Vulnerability identified:**

**Proposed improvement:**

**Why this approach was selected:**

**Potential limitations:**

### 2. Implementation Record

| File or Component | Change Made | Security Rationale |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 3. Verification

Repeat the relevant tests after implementing the improvement.

| Test Scenario | Behaviour Before | Behaviour After | Result |
|---|---|---|---|
| Normal content | | | |
| Content containing HTML | | | |
| Approved malicious test content | | | |
| Unexpected formatting | | | |

### 4. Evaluation

Did the improvement prevent the identified unsafe behaviour?

**Your response:**

Did it affect any legitimate application functionality?

**Your response:**

What additional controls might be appropriate?

**Your response:**

## Part 6 — Network Security and App Transport Security

Investigate how My Dental Companion communicates with its backend and how network transport security is configured.

### 1. Network Configuration Investigation

Identify the application's network communication settings.

**Relevant configuration file or component:**

**Backend address or endpoint:**

**Transport protocol used:**

**App Transport Security configuration:**

### 2. Security Analysis

What protections does HTTPS provide for application-to-backend communication?

**Your analysis:**

What risks could arise when an application permits insecure network connections?

**Your analysis:**

Why might development environments use network security exceptions?

**Your analysis:**

What should be considered before carrying those exceptions into a production application?

**Your analysis:**

### 3. Implementation Record

Document the changes made to improve network transport security.

| Configuration or Component | Original Behaviour | Change Made | Security Rationale |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |

### 4. Verification

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Approved secure connection | | | |
| Insecure connection | | | |
| Backend unavailable | | | |
| Connection or certificate error | | | |

What security and functionality trade-offs did you encounter?

**Your response:**

## Part 7 — Application Security Review

Review the security improvements explored during the day.

| Area | Identified Risk | Improvement Implemented | Evidence | Remaining Concern |
|---|---|---|---|---|
| On-device AI processing | | | | |
| Generated content handling | | | | |
| HTML rendering | | | | |
| Network communication | | | | |
| Error handling | | | | |

### 1. Prioritization

Which security improvement would you consider most important for protecting application users?

**Your recommendation and rationale:**

### 2. Remaining Risks

Identify risks that would require further investigation before production deployment.

**Your findings:**

### 3. Human Oversight

Where should the application require user review or confirmation rather than relying automatically on generated content?

**Your recommendation:**

## Part 8 — Peer Review

Exchange your implementation and findings with another learner or team.

**Reviewer / Team:**

**Areas reviewed:**

**Security issues identified:**

**Feedback received:**

**Recommendations for improvement:**

**Changes made following the review:**

## Part 9 — Reflection

How did working with on-device AI change your understanding of AI application architecture?

**Your response:**

What did the HTML rendering investigation reveal about the risks of treating generated content as trusted?

**Your response:**

How do application-level security controls and network transport protections complement one another?

**Your response:**

Which technical or security trade-offs were most challenging during this activity?

**Your response:**

What additional testing or safeguards would you recommend before deploying the application in a production environment?

**Your response:**

## Evidence Checklist

- [ ] Application architecture and data flow investigated
- [ ] On-device AI implementation documented
- [ ] Model output and limitations evaluated
- [ ] Privacy and architecture comparison completed
- [ ] Unsafe HTML rendering investigated
- [ ] Rendering improvements implemented and tested
- [ ] Network transport security reviewed
- [ ] App Transport Security changes documented and verified
- [ ] Application security review completed
- [ ] Peer review completed
- [ ] Final reflection completed

---

[Back to Daily Workbooks](README.md)
