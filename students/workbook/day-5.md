 
# Day 5

## Activity 1 — Validate, Harden & Prepare for Release

*Duration: 90 minutes*  
*Format: Hands-on technical challenge*  
*Application: My Dental Companion*  
*Starting branch: `Day5-starter` (application and backend)*

## Activity Overview

Evaluate My Dental Companion, address the planted security vulnerabilities, and determine whether the application is ready for release.

Working in pairs, you will:

1. Conduct a brief AI reliability check using prepared dental notes.
2. Run three security scanners and investigate their findings.
3. Remediate the three planted vulnerabilities.
4. Rerun scans and verify existing application functionality, including safe handling of invalid ZIP files.
5. Prepare a short Release-Readiness Report with your findings and recommendation.

### Your Final Deliverable

By the end of the activity, you will have completed a **Release-Readiness Report** containing:

- AI evaluation results.
- Security findings, classifications, and priorities.
- Changes made and before-and-after evidence.
- Functional retesting results and remaining risks.
- A final recommendation: **Go, Conditional Go, or No-Go**.

Use this workbook to record your findings as you complete each task. Your final report will summarize the evidence you have collected.

---

## Task 1 — AI Reliability Check

Evaluate whether the application's AI-generated results accurately represent the information provided in fictional dental notes. Enter each note into My Dental Companion and review the generated output.

For each test, evaluate:

- **Accuracy:** Is the generated information supported by the original note?
- **Completeness:** Are important details and follow-up actions captured?
- **Uncertainty:** Does the AI preserve information that is tentative, missing, or unconfirmed?
- **Structure:** Are the results presented in the expected format?

Record **Pass, Fail, or Needs Review**, with a brief explanation.

### Test 1 — Clear Information

**Dental Note**

> Patient attended a routine cleaning on October 15. The hygienist recommended a follow-up appointment in six months. The patient's insurance covered 80% of the $200 visit, leaving a balance of $40.

#### Evaluation Record

**Overall result:** Pass / Fail / Needs Review

**What did the AI extract correctly?**

**Response:**

**Were any details missing, incorrect, or unsupported?**

**Response:**

### Test 2 — Ambiguous Information

**Dental Note**

> Patient discussed getting a crown on the upper right molar. The dentist suggested scheduling an appointment sometime next month, but the patient has not confirmed. Insurance coverage is still being reviewed.

#### Evaluation Record

**Overall result:** Pass / Fail / Needs Review

**How did the AI represent the tentative appointment?**

**Response:**

**Did it preserve the uncertainty around insurance coverage?**

**Response:**

### Test 3 — Missing Information

**Dental Note**

> Patient called about tooth sensitivity. The dentist recommended a follow-up examination, but no appointment date has been selected. Treatment costs and insurance coverage have not yet been determined.

#### Evaluation Record

**Overall result:** Pass / Fail / Needs Review

**Did the AI invent any missing information?**

**Response:**

**How were unknown appointment dates, costs, and insurance details represented?**

**Response:**

### Task 1 — Summary

**Based on these three tests, what is your assessment of the AI feature's reliability?**

**Response:**

---

## Task 2 — Run the Security Scans

Identify potential security vulnerabilities in the Day 5 starter application using three security scanning tools.

You will use:

- **OSV-Scanner** — Dependency analysis.
- **mobsfscan** — Static code analysis.
- **TruffleHog** — Secrets detection.

For each scan:

1. Save the original scan report.
2. Identify the relevant finding and its location.
3. Describe the potential security risk.
4. Classify and prioritize the finding.

Use the approved technical instructions for running each scanner.

### Scan 1 — OSV-Scanner

**Focus:** Swift package dependencies and the ZIPFoundation vulnerability.

**Why could this dependency present a security risk?**

**Response:**

### Scan 2 — mobsfscan

**Focus:** Swift source code and authentication token logging.

**What could happen if authentication tokens are written to application logs?**

**Response:**

### Scan 3 — TruffleHog

**Focus:** Embedded synthetic token in the application source files.

**Why should embedded credentials or secrets be removed, even when they are not actively used?**

**Response:**

**Important:** Do not copy actual credential values into this workbook. Record the finding type and location instead.

---

## Task 3 — Findings Summary

**Which finding would you prioritize first, and why?**

**Response:**

---

## Task 4 — Investigate and Remediate

Review the scanner findings and implement the required security fixes.

You will address three planted vulnerabilities:

1. Update ZIPFoundation to version `0.9.18`.
2. Remove the statement that writes the authentication token to application logs.
3. Remove the embedded synthetic token from `Day5SyntheticSecrets.swift` and update any remaining code references so the application builds successfully.

### Remediation 1 — ZIPFoundation

**Required change:** Update the vulnerable dependency to version `0.9.18`.

**Describe the remediation performed.**

**Response:**

### Remediation 2 — Authentication Token Logging

**Required change:** Remove the statement that writes the authentication token to the application logs.

**Remediation performed:**

### Remediation 3 — Embedded Synthetic Secret

**Required change:** Remove the synthetic `apiToken` declaration from `Day5SyntheticSecrets.swift`.

Update the remaining `authorizationHeader` property to remove its reference to `apiToken`, ensuring the application builds successfully.

For this lab, replace the demonstration property's value with `"Bearer "`.

**Important:** This is a temporary, compile-safe placeholder for unused demonstration code, not a secure authentication implementation. In a production application, unused authorization code should be removed or replaced with proper secure token handling.

**Why is it important to remove embedded credentials from source code, and why must we verify that the application still builds after removing them?**

**Response:**

### Remediation Summary

**Were there any issues or incomplete changes?**

**Response:**

---

## Task 5 — Retest and Verify

Verify that the security fixes worked and that existing application functionality remains intact.

You will:

1. Rerun each security scanner.
2. Compare the new results with the original reports.
3. Confirm the three planted findings are no longer reported in the relevant scan scope.
4. Test existing application functionality.
5. Record any remaining failures or incomplete tests.

### Part A — Security Verification

**Were all three planted findings resolved? Did the new scans identify any additional findings requiring attention?**

**Response:**

### Part B — Functional Testing

After identifying and remediating security vulnerabilities, it is important to verify that the application still functions correctly.

Regression testing checks whether changes to an application have unintentionally affected existing functionality. A successful security scan does not necessarily mean the application works as expected. Both security and functionality must be verified.

In this activity, you will run the remediated Dental Notes application in the iPhone simulator and test its core features.

#### B.1 Launch the Application

Before launching the application, confirm that your FastAPI backend is running and that `BackendConfig.plist` points to `http://127.0.0.1:8000`.

1. Open `Dental Notes.xcodeproj` in Xcode.
2. Select the **Dental Notes Server** scheme.
3. Select the **iPhone 18 Pro** simulator.
4. Press **Command + R** to build and run the application.
5. Confirm that the application launches without errors.

If the application fails to build, review your security remediation changes and resolve any remaining code errors.

#### B.2 Test Core Application Functionality

After successfully launching the application in the iPhone simulator, complete the following functional tests to verify that the security remediations have not affected existing application functionality.

**Important:** Use only fictional dental notes and practice account information.

##### Test 1: Authentication

1. Open the application and navigate to the authentication screen.
2. Create a new practice account using a unique password of at least 12 characters.
3. Confirm that you can successfully authenticate and access the Notes interface.
4. Verify that the application does not display any authentication errors.

**Expected Result:** The application successfully authenticates the user and displays the Notes interface.

##### Test 2: Create a Dental Note

1. Navigate to the Notes interface.
2. Create a new note using the following fictional dental information:

   > Routine dental checkup completed. Schedule a follow-up appointment in six months.

3. Save the note.
4. Open the saved note and verify that its contents are correct.
5. Confirm that the note displays its associated timestamps.

**Expected Result:** The note is successfully created, saved, and displayed with the correct information.

##### Test 3: Verify Note Persistence

1. After saving your note, stop the application using the **Stop** button in Xcode.
2. Restart the application using **Command + R**.
3. Return to the Notes interface.
4. Locate the note created in Test 2.
5. Verify that the note remains available and its contents have not changed.

**Expected Result:** The previously saved note remains available after restarting the application.

##### Test 4: Export a ZIP Backup

1. Navigate to **Settings**.
2. Select **Export Backup**.
3. Choose **Export ZIP Backup**.
4. Wait for the application to generate the backup.
5. Confirm that the application displays a successful export message.

**Expected Result:** The application successfully generates a ZIP backup named `DentalNotes-Backup.zip` without errors.

##### Test 5: Import a ZIP Backup

1. Navigate to **Settings**.
2. Select **Import Backup**.
3. Choose **Choose ZIP Backup**.
4. Select the ZIP file generated in Test 4.
5. Allow the application to process the backup.
6. Review the import confirmation message.
7. Return to the Notes interface and confirm that the existing note is still available.
8. Verify that the import did not create a duplicate of the existing note.

**Expected Result:** The application successfully processes the ZIP backup, preserves the existing note, and does not create a duplicate record.

**Note:** This test verifies that the ZIP import process works correctly when the note already exists. It does not test recovery of a previously deleted note.

#### B.3 Record Your Test Results

##### Functional Testing Observations

Record the outcome of each test below. Use **Pass, Fail, or Not Tested**, and provide a brief observation or evidence reference to support your result.

| Functional Test | Status (Pass / Fail / Not Tested) | Observation / Evidence |
|---|---|---|
| Authentication | | |
| Create a Dental Note | | |
| Verify Note Persistence | | |
| Export a ZIP Backup | | |
| Import a ZIP Backup | | |

##### Functional Test Observations

**1. Did any of the security changes affect the application's existing functionality? If so, describe what happened.**

**Response:**

**2. Were there any unexpected behaviours, errors, or incomplete tests? If so, explain how you investigated them.**

**Response:**

### Part C — Before-and-After Evidence

**What evidence demonstrates that the application is more secure after remediation?**

**Response:**

---

## Task 6 — Release-Readiness Report

Prepare a short report summarizing your AI evaluation, security findings, remediation work and verification results.

Use the evidence already recorded in Tasks 1–5. You do not need to repeat the full scan reports or test records.

### 1. AI Evaluation

**What did you test, and did the application behave as expected?**

Summarize the results of the three AI reliability tests. Identify any accuracy, completeness, uncertainty or formatting concerns.

**Summary:**

**Overall AI reliability assessment:** Pass / Fail / Needs Review

### 2. Security Findings

**What vulnerabilities were identified, and how were they prioritized?**

**Summary of security concerns:**

### 3. Remediation

**What changes did you make?**

**Response:**

**Were all required remediations completed successfully?**

**Response:**

### 4. Verification

**What evidence demonstrates that the fixes worked?**

Summarize the before-and-after security scans and functional test results.

**Security verification:**

**Functional verification:**

**Evidence references:**

### 5. Remaining Risks

**What findings, limitations or incomplete tests still require attention?**

**Response:**

If no additional risks were identified, state that explicitly and describe any limitations in the testing performed.

### 6. Release Recommendation

**Would you recommend releasing My Dental Companion?**

Select one:

- [ ] **Go** — The application meets the evaluated release requirements, and no blocking issues remain.
- [ ] **Conditional Go** — Release may proceed only after specified conditions are satisfied.
- [ ] **No-Go** — Unresolved findings or insufficient evidence prevent a release recommendation.

#### Justification

Explain your recommendation using the AI evaluation, security findings, remediation results, functional testing and remaining risks.

**Response:**

**If Conditional Go, what conditions must be satisfied before release?**

**Response:**

**If No-Go, what must be addressed before the application can be reconsidered?**

**Response:**

---

## Final Reflection

**What was the most important security issue you identified during this challenge, and how did your testing influence your release recommendation?**

**Response:**

**Final Reminder:** A successful build or a clean scanner result alone does not establish release readiness. Your recommendation should be supported by the combined evidence from AI reliability, security scanning, remediation and functional testing.
