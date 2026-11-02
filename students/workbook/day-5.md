
# Day 5 — Security Scanning and Remediation

**Challenge:** Conduct a security assessment of My Dental Companion using automated security scanning tools. Investigate vulnerabilities in third-party dependencies, application source code, and exposed credentials. Implement appropriate remediations, verify their effectiveness, and evaluate the security of the application and supporting backend.

Use this workbook to document your investigation, findings, remediation decisions, testing, and reflections. Follow the Day 5 Activity Brief and Student Daily Technical Setup for technical instructions.

## Part 1 — Establish the Security Baseline

Before making changes, examine the Day 5 starter application and supporting backend.

### 1. Application Investigation

Identify the main components that will be included in your security assessment.

| Component | Purpose | Potential Security Concerns |
|---|---|---|
| iOS application | | |
| Third-party dependencies | | |
| Authentication and session handling | | |
| Backend services | | |
| Logging and error handling | | |
| Backup and restore functionality | | |

### 2. Initial Security Assessment

Which components are most likely to contain security vulnerabilities?

**Your analysis:**

What types of vulnerabilities can automated security scanners identify?

**Your analysis:**

What types of security problems might automated scanners fail to identify?

**Your analysis:**

Why is it important to establish a baseline before modifying the application?

**Your analysis:**

## Part 2 — Dependency Security with OSV-Scanner

Investigate the application's third-party dependencies and identify known security vulnerabilities.

### 1. Scan Configuration

**Tool:** OSV-Scanner

**Project or directory scanned:**

**Dependency files examined:**

**Scan command used:**

### 2. Initial Findings

| Dependency | Installed Version | Finding or Advisory | Severity, if Reported | Recommended Action |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |
| | | | | |

### 3. Dependency Investigation

Examine the reported vulnerability associated with the ZIPFoundation dependency.

**Installed version:**

**Affected functionality:**

**Description of the reported vulnerability:**

**Potential impact on the application:**

**Recommended version or remediation:**

### 4. Security Analysis

Why can third-party dependencies introduce security risks even when the application's own code is secure?

**Your analysis:**

How would you determine whether a reported vulnerability is relevant to this application?

**Your analysis:**

What should be considered before updating a dependency?

**Your analysis:**

## Part 3 — Source Code Security with mobsfscan

Use mobsfscan to investigate potential security weaknesses in the application source code.

### 1. Scan Configuration

**Tool:** mobsfscan

**Project or directory scanned:**

**Scan command used:**

**Report location:**

### 2. Initial Findings

| Finding | File or Component | Security Concern | Recommended Action |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |

### 3. Investigate Sensitive Information Logging

Examine how the application handles authentication or session information in logs.

**Relevant file or component:**

**Information being logged:**

**Conditions under which logging occurs:**

**Potential security impact:**

### 4. Risk Analysis

Why can logging authentication tokens or other sensitive values create security risks?

**Your analysis:**

Who or what might have access to application logs?

**Your analysis:**

How can developers preserve useful diagnostic information without exposing sensitive data?

**Your recommendation:**

What additional source-code security issues would you investigate beyond the scanner's reported findings?

**Your analysis:**

## Part 4 — Secret Detection with TruffleHog

Investigate the application for embedded credentials, tokens, or other potentially sensitive values.

### 1. Scan Configuration

**Tool:** TruffleHog

**Repository or directory scanned:**

**Scan command used:**

**Report location:**

### 2. Initial Findings

| Finding | File or Location | Type of Sensitive Information | Risk Assessment |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |

### 3. Investigate the Embedded Token

The workshop starter includes a synthetic token for security testing.

**File or component containing the token:**

**How the token is used or referenced:**

**Why embedding a token in application source code is risky:**

**Recommended remediation:**

### 4. Security Analysis

What is the difference between detecting a potential secret and confirming that it represents a genuine security exposure?

**Your analysis:**

Why might removing a secret from the current source file be insufficient if it has already been committed to a repository?

**Your analysis:**

What additional actions would be necessary if a real production credential had been exposed?

**Your recommendations:**

How should applications manage credentials and configuration values securely?

**Your recommendations:**

**Security reminder:** Use only the approved workshop repository and synthetic test values. Do not copy real credentials into this workbook or scan unrelated repositories.

## Part 5 — Consolidate and Prioritize Findings

Review the results of all three security scans.

### 1. Consolidated Findings Register

| ID | Tool | Finding | Affected Component | Risk / Severity | Remediation Priority |
|---|---|---|---|---|---|
| F-01 | | | | | |
| F-02 | | | | | |
| F-03 | | | | | |
| F-04 | | | | | |

### 2. Prioritization

Identify the factors that influenced your remediation priorities.

| Consideration | Your Assessment |
|---|---|
| Potential impact | |
| Likelihood of exploitation | |
| Exposure of sensitive information | |
| Ease of remediation | |
| Dependencies or implementation constraints | |

### 3. Decision-Making

Which finding would you address first, and why?

**Your response:**

Did any findings require manual investigation before determining their significance?

**Your response:**

How would you distinguish a false positive from a genuine vulnerability?

**Your response:**

## Part 6 — Implement Security Remediations

Apply the required security improvements and document your changes.

### 1. Remediation Record

| Finding | File or Component | Change Implemented | Security Rationale |
|---|---|---|---|
| Vulnerable dependency | | | |
| Sensitive information logging | | | |
| Embedded token | | | |
| Additional finding, if applicable | | | |

### 2. Dependency Remediation

Document the ZIPFoundation dependency update.

**Original version:**

**Updated version:**

**Files or package settings modified:**

**How compatibility was verified:**

### 3. Sensitive Logging Remediation

**Original behaviour:**

**Change implemented:**

**How the application preserves appropriate diagnostic information:**

### 4. Embedded Token Remediation

**Original location:**

**Change implemented:**

**How the application avoids relying on an embedded secret:**

### 5. Implementation Considerations

Did any remediation introduce changes to application functionality?

**Your observations:**

Were there any trade-offs between security, maintainability, and developer convenience?

**Your analysis:**

What additional improvements would you recommend?

**Your recommendations:**

## Part 7 — Backend Backup and Restore Security

Investigate the backend's backup and restore functionality.

### 1. Functionality Investigation

**Relevant backend component or endpoint:**

**Purpose of the restore functionality:**

**Input or data accepted:**

**Expected application behaviour:**

### 2. Security Considerations

| Area | Potential Risk | Recommended Control |
|---|---|---|
| Authorization | | |
| Input validation | | |
| Data integrity | | |
| Error handling | | |
| Logging and auditability | | |

### 3. Functional and Security Testing

Use only the approved lab environment and supplied test data.

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Valid authorized restore | | | |
| Invalid or incomplete input | | | |
| Unauthorized request | | | |
| Restore failure | | | |

### 4. Analysis

Why should backup and restore operations require strong authorization controls?

**Your analysis:**

How could insufficient input validation affect application data or backend security?

**Your analysis:**

What safeguards would be necessary before enabling this functionality in production?

**Your recommendations:**

## Part 8 — Verify the Remediations

Repeat the relevant security scans and functional tests after implementing the changes.

### 1. Before-and-After Scan Results

| Finding | Initial Scan Result | Result After Remediation | Status |
|---|---|---|---|
| Vulnerable dependency | | | |
| Sensitive information logging | | | |
| Embedded token | | | |
| Additional finding | | | |

### 2. Functional Regression Testing

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Application builds successfully | | | |
| Application launches | | | |
| Authentication works | | | |
| Backend connection works | | | |
| Core note functionality works | | | |
| Backup and restore work as intended | | | |

### 3. Verification Analysis

Did all original findings disappear from the scan results?

**Your observations:**

If a finding remains, what might explain the result?

**Your analysis:**

Does a clean scan report prove that the application is secure? Explain.

**Your response:**

What additional manual testing or security review would you recommend?

**Your recommendations:**

## Part 9 — Final Security Assessment

Prepare a concise summary of the application's security posture following your investigation and remediation.

### 1. Assessment Summary

| Area | Initial Security Concern | Improvement Made | Remaining Risk |
|---|---|---|---|
| Dependencies | | | |
| Source code | | | |
| Credential management | | | |
| Backend functionality | | | |
| Overall application security | | | |

### 2. Outstanding Findings

Identify any issues that were not fully resolved.

| Outstanding Issue | Potential Impact | Recommended Next Step |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 3. Production Readiness

Based on your assessment, would you recommend releasing the application to production in its current state?

**Recommendation:**

**Supporting evidence:**

**Conditions or additional work required:**

## Part 10 — Peer Review

Exchange your security assessment and remediation results with another learner or team.

**Reviewer / Team:**

**Findings reviewed:**

**Remediations reviewed:**

**Additional risks identified:**

**Feedback received:**

**Changes made or proposed following the review:**

## Part 11 — Reflection

What did automated security scanning reveal that was not immediately apparent from reviewing the application's functionality?

**Your response:**

Which security finding required the most investigation or technical judgment?

**Your response:**

How did you verify that your remediations addressed the identified risks without breaking application functionality?

**Your response:**

What are the limitations of relying on automated security scanning tools?

**Your response:**

How would you incorporate dependency scanning, source-code analysis, and secret detection into an ongoing secure development workflow?

**Your response:**

Looking back across all five workshop days, how has your approach to designing and evaluating secure AI-enabled applications changed?

**Your response:**

## Evidence Checklist

- [ ] Initial application and backend investigation documented
- [ ] OSV-Scanner executed and findings recorded
- [ ] mobsfscan executed and findings recorded
- [ ] TruffleHog executed and findings recorded
- [ ] Security findings consolidated and prioritized
- [ ] Dependency remediation documented
- [ ] Sensitive logging remediation documented
- [ ] Embedded token remediation documented
- [ ] Backend backup and restore functionality investigated
- [ ] Security scans repeated after remediation
- [ ] Functional regression testing completed
- [ ] Final security assessment documented
- [ ] Peer review completed
- [ ] Final reflection completed

---

[Back to Daily Workbooks](README.md)
