# Mentor Training & Module 1 Delivery Guide

## Purpose of This Document 

This guide serves two complementary purposes:

## 1. Mentor Preparation & Training Framework

Provides a structured approach to preparing mentors to support the cybersecurity program. It outlines the knowledge, technical preparation, facilitation skills, and resources needed to guide learners through the Challenge-Based Learning (CBL) experience.

The goal is to ensure mentors understand the learning journey, can confidently support hands-on activities, troubleshooting, testing, and reflection, and encourage independent problem-solving while maintaining learner ownership.

## 2. Module 1: Specific Guidance & Resources

Provides practical guidance to prepare mentors for Year 2, Module 1, including learning objectives, challenge activities, technical setup, demonstrations, expected outcomes, troubleshooting, and supporting resources.

This section serves as a reference for mentors before, during, and after delivery, helping them effectively support learners and collaborate with the instructional team.

---

## Module & Challenge Walkthrough

In Year 2 Module 1, learners work with My Dental Companion, a SwiftUI application, to explore AI integration, secure architecture, on-device machine learning, and application security. Across five days, they investigate vulnerabilities, implement improvements, test their solutions, and evaluate security decisions. Mentors provide technical guidance and use reference implementations to demonstrate possible solutions.

### What learners should learn

The five objectives are to:

1. Identify security risks in hosted and on-device AI.
2. Apply secure architecture and platform protection principles.
3. Train, evaluate, and integrate an on-device machine learning model.
4. Implement and test application security controls.
5. Assess and remediate vulnerabilities using security scanning tools.

### What the challenges ask learners to do

| Day | Challenge | Expected outcome |
|---|---|---|
| Day 1 — Hosted AI | Complete an AI request and investigate prompt injection. | Working AI processing, improved prompts, and test evidence. |
| Day 2 — Platform Security | Implement an App Intent, secure token storage, and backend-mediated AI processing. | Device authentication, Keychain integration, and tested backend operations. |
| Day 3 — Create ML | Clean training data, compare classifiers, and integrate a trained model. | Exported Core ML model and on-device predictions with category scores. |
| Day 4 — On-Device AI | Implement local generation and investigate unsafe rendering and HTTP transport. | Working generation, safe summary displays, and verified transport protections. |
| Day 5 — Security Testing | Run security scans, assess findings, and fix identified weaknesses. | Remediated dependency, token logging, and embedded secret, with before-and-after evidence. |

### How mentors support the challenges

| Stage | Mentor responsibility |
|---|---|
| Before the session | Verify the starter application, backend, required tools, datasets, and reference implementations. |
| Investigation | Help learners locate relevant code, understand risks, and plan their approach. |
| Build & Test | Support debugging, guide testing, and help learners interpret results without completing the challenge for them. |
| Evaluation | Review evidence, demonstrate reference solutions, and discuss limitations and remaining risks. |

### What learners should record

For each challenge, learners should document:

1. **Starting point:** The issue, behaviour, or task being investigated.
2. **Changes:** What they implemented and why.
3. **Testing:** Expected and actual results, including failure scenarios.
4. **Evidence:** Code changes, screenshots, model results, or scanner reports.
5. **Reflection:** What improved, what remains unresolved, and what further testing is needed.

Mentors should encourage learners to explain their decisions rather than simply demonstrate working functionality. Use fictional notes, approved lab credentials, and synthetic data throughout the module.

# Technical Environment & Setup

This guide supports mentors in preparing, validating, and maintaining the technical environment for all five days of Year 2, Module 1.

Mentors should complete the general environment preparation before the program begins and verify the relevant application, backend, and demonstrations before each workshop.

Students are responsible for installing the required development tools before Day 1. Mentors are responsible for confirming technical readiness, providing the correct daily starter materials, and supporting learners during setup and delivery.

This guide should be used alongside the Student Technical Preparation, Student Daily Technical Setup, and Day 1–5 Instructor Guides.

## 1. Pre-Program Technical Preparation

### Access Materials on GitHub

Year 2 uses two primary repositories:

| Repository | Purpose |
|---|---|
| `apple-year-2-secure` | My Dental Companion iOS application, including daily starter and reference branches |
| `apple-year-2-backend` | Supporting backend services for server-connected activities |

Mentors should confirm repository access, verify the required branches, and prepare separate working copies of student starters and mentor references.

#### Application and Backend Versions

| Day | Student Application | Mentor Reference | Backend |
|---|---|---|---|
| Day 1 | `Day-1-local` | `day1-prompt-injection`, `Day-2-server` | None for learners; main for the Day-2-server reference |
| Day 2 | `Day-2-server` | `Day-3-server` | main |
| Day 3 | `Day-3-server` | `Day-4-server` | main |
| Day 4 | `Day-4` | `Day4-XSS`, `Day4-final` | main |
| Day 5 | `Day5-starter` | `Day5-final` | Day5-starter |

Branch names are case-sensitive. Mentors should verify the approved commits before delivery, particularly when instructor guides reference specific files or lines of code.

The `Day-3-server` application serves as the completed reference for Day 2 and the confirmed student starter for Day 3.

### Verify the Development Environment

Before the program, mentors should install and test the tools required across all five days.

| Tool | Verification |
|---|---|
| Xcode | Xcode 27.1 installed; projects build successfully. Do not update macOS or Xcode during the week |
| iPhone Simulator | iOS 27 Simulator runtime installed and available; use the iPhone 18 Pro |
| Git | Repository access and cloning work |
| Homebrew | Package installation is available |
| Python 3.12 and `uv` | Backend environments can be created |
| Apple Numbers | CSV files open correctly |
| Create ML | Training and model export are available |
| Apple Shortcuts | App Intents can be accessed and tested |
| Apple Intelligence | Apple silicon Mac on macOS 27.2, with Apple Intelligence on and its model fully downloaded. Needed on Day 4 and for Day 5 Task 1 |
| OSV-Scanner | Scanner launches successfully |
| mobsfscan | Source-code scanner runs through `uv` |
| TruffleHog | Scanner launches successfully |

#### Command-Line Verification

Open Terminal:

    git --version
    xcodebuild -version
    xcrun simctl list devices available
    uv --version
    osv-scanner --version
    trufflehog --version

Verify mobsfscan:

    uv tool run --python 3.12 \
      --from mobsfscan==1.0.1 \
      mobsfscan --version

Resolve missing dependencies, incompatible software versions, and device limitations before the program.

### Projects to Open

The primary iOS project is:

    Dental Notes.xcodeproj

| Application Mode | Scheme | Use |
|---|---|---|
| Local application | Dental Notes | Day 1 local note and hosted AI activities |
| Server-connected application | Dental Notes Server | Backend-connected activities |

To verify an application:

1. Download the required branch into a dedicated workspace.
2. Open `Dental Notes.xcodeproj` in Xcode.
3. Select the appropriate application scheme.
4. Choose an approved Simulator or physical device.
5. Allow Swift Package Manager to resolve dependencies.
6. Press Command-R to build and launch the application.
7. Confirm that the expected application functionality is available.

Use separate working copies for student starters and mentor references. Do not overwrite student work when switching application versions.

### Prepare Student Materials

Before Day 1, ensure that students have received:

- Student Workbook
- Student Daily Technical Setup instructions
- Repository access instructions

Day-specific application branches, datasets, and configuration instructions should be introduced at the appropriate workshop.

Do not include mentor answer keys or completed reference implementations in the student preparation package.

### Confirm Student Readiness

Mentors should distribute the pre-program technical preparation instructions sufficiently in advance for students to complete installations and request support.

Before Day 1, confirm that students:

1. Have installed the required development tools.
2. Can access the approved GitHub repositories.
3. Have a working Xcode and Simulator environment.
4. Have received the required learning materials.
5. Have identified any software or device compatibility issues.
6. Have installed the Day 5 tools: Homebrew, uv with Python 3.12, OSV-Scanner, TruffleHog and mobsfscan. Installing Homebrew needs an administrator account, as do the two sudo commands in the Day 5 guide, section 1.
7. Have turned on Apple Intelligence and let its model finish downloading before Day 4.

Where possible, resolve installation and access issues before the first workshop.


## 2. Daily Technical Verification

### Day 1 — Hosted AI and Prompt Injection

**Student starter:** `Day-1-local`  
**Mentor demonstrations:** `day1-prompt-injection`, `Day-2-server`

#### Before Students Begin

1. Open `Day-1-local` using the `Dental Notes` scheme.
2. Confirm that the application builds and launches. The app opens on a lock screen: type any digits, such as 1234. On Day-1-local, Apple Intelligence is the default: open Settings and choose Third-party provider.
3. Create, save, and reopen a fictional dental note.
4. Verify that the hosted AI request remains unfinished in the starter.
5. Prepare `day1-prompt-injection` in a separate working copy.
6. Configure the approved endpoint, model, and training API key in the local `ThirdPartyAIConfig.plist`.
7. Confirm that the intermediate implementation can send a hosted request and display a result.
8. Rehearse the controlled prompt injection demonstration using the supplied fictional test content.
9. Prepare `Day-2-server` as the completed reference: start the backend (main), copy `BackendConfig.example.plist` to `BackendConfig.plist`, sign in as `demo_user` and put the training key in `LabAIConfig.swift` privately. `LabAIConfig.swift` is tracked by Git, so restore it before switching branches.

#### Expected Behaviour

- The student starter supports local note creation and review.
- Hosted AI integration requires student implementation.
- The intermediate reference supports the hosted request.
- The mentor can demonstrate the prompt weakness and its correction.

**Security reminder:** Keep real API keys out of projected code, screenshots, and shared files. The local starter does not require a running application backend.

At the start of Day 1, mentors help learners build `Day-1-local` and create `ThirdPartyAIConfig.plist` from the example.

### Day 2 — Secure Architecture and Platform Protections

**Student starter:** `Day-2-server`  
**Mentor reference:** `Day-3-server`

#### Before Students Begin

1. Prepare the `Day-2-server` student application.
2. Start the backend (`main`) with the `AI_ENDPOINT`, `AI_MODEL`, `AI_API_KEY` and `JWT_SECRET_KEY` variables from the Day 2 guide, section 2. The AI variables are needed for Security task 3 and the backend AI demonstration.
3. Verify that the backend responds at `http://127.0.0.1:8000/status`.
4. Confirm that `BackendConfig.plist` points to the local backend.
5. Select the `Dental Notes Server` scheme.
6. Launch the application and sign in using the approved test account. When asked for the iPhone passcode, type any digits.
7. Confirm that the starter retains the intended unfinished or insecure functionality.
8. Prepare `Day-3-server` in a separate working copy.
9. Rehearse the Create Follow-up App Intent demonstration.
10. Verify the device authentication and Keychain demonstrations.
11. Confirm that the reference implementation routes hosted AI requests through the backend.

#### Expected Behaviour

- Both application versions connect to the approved backend.
- Test-account authentication works.
- The student starter contains the intended challenge requirements.
- The mentor reference demonstrates the completed App Intent, device authentication, Keychain storage, and backend AI integration.

Learners need only the Simulator. They run the App Intent from the Shortcuts app: tap the back arrow, then Library, Apps, My Dental Companion. After it runs, pull down on Followups to refresh. The Simulator has no passcode, so the authentication prompt and the cancel test cannot be shown there; record them as “not run”, or use a passcode-protected iPhone (optional).

**Backend:** `main` at `9d18a42` (Nov 2) or later, which accepts 2,048-character text. An older backend returns 422 on the 2,048-character test.

### Day 3 — Create ML and Text Classification

**Student starter:** `Day-3-server`

#### Before Students Begin

1. Open the `Day-3-server` application and confirm that it builds.
2. Verify that Apple Numbers and Create ML are available.
3. Open the supplied training and testing datasets.
4. Review the data-cleaning instructions and expected transformations.
5. Rehearse importing the prepared training data into Create ML.
6. Train and evaluate a reference text classification model.
7. Export the model as an `.mlmodel` file.
8. Verify the model integration workflow in the application.
9. Prepare a reference model and expected evaluation results for troubleshooting.

#### Required Datasets

| Dataset | Purpose |
|---|---|
| `day3_student_unclean_training_1000_final.csv` | Student training data |
| `day3_dental_test_300_challenging.csv` | Independent evaluation data |

#### Expected Behaviour

- Both datasets open successfully.
- Create ML accepts the prepared training data.
- A text classification model can be trained, evaluated, and exported.
- The approved application supports the planned model integration workflow.

**Technical confirmation required:** Whether Day 3 requires a running backend and which configuration should be used.

### Day 4 — On-Device AI and Application Security

**Student starter:** `Day-4`  
**Mentor references:** `Day4-XSS`, `Day4-final`  
**Backend:** `main`

#### Reviewed Reference Versions

| Component | Commit |
|---|---|
| Student starter | `b9e25af` |
| Instructor demo (Day4-XSS) | `9d693a6` |
| Reference fixes (Day4-final) | `f9c9716` |
| Backend | `9d18a42` |

Updated Nov 2: the three app branches removed one line from `PromptSystem.md` (“- Do not provide medical advice.”), and the backend raised its text limits to 2,048 characters.

#### Before Students Begin

1. Prepare the `Day-4` student application.
2. Start the approved backend using the supplied lab database.
3. Verify authentication and sample note access.
4. Confirm that the starter builds and launches.
5. On an Apple silicon Mac on macOS 27.2, turn on Apple Intelligence and let its model finish downloading. On Day-4, Settings > AI Method must list Apple Intelligence.
6. Create the three demonstration copies from the Day 4 guide, section 2: `day4-xss` (`Day4-XSS`), `day4-ats-blocked` (`Day4-XSS` with the broad ATS exception removed and the HTTP endpoint kept) and `day4-final` (`Day4-final`). Copy `BackendConfig.plist` into each.
7. Rehearse the unsafe HTML rendering demonstration using approved test content.
8. Rehearse the network transport security demonstration.
9. Prepare `Day4-final` and verify the corrected behaviours.

#### Expected Behaviour

- The student starter connects to the backend.
- The required note workflow is available.
- The mentor can demonstrate on-device generation in a supported environment.
- The intermediate reference exposes the intended security weaknesses.
- The completed reference demonstrates the rendering and transport security improvements.

If Apple Intelligence is unavailable on a learner Mac, keep manual editing available and pair that learner with a Mac where it works; do not silently switch the exercise to a hosted provider. Keep the supplied XSS screenshots and a recording of the normal feature and transport tests in case a live run fails.

### Day 5 — Security Scanning and Remediation

**Student application:** `Day5-starter`  
**Mentor reference:** `Day5-final`  
**Backend:** `Day5-starter`

#### Reviewed Reference Versions

| Component | Commit |
|---|---|
| Student application | `efbff01` |
| Backend | `daec362` |
| Mentor reference | `257969f` |

#### Before Students Begin

1. Prepare the application `Day5-starter` branch.
2. Prepare the backend `Day5-starter` branch.
3. Start the backend using the approved Python environment and lab database.
4. Confirm that the backend responds at `/status`.
5. Set `BackendConfig.plist` to `http://127.0.0.1:8000`; the example uses port 8080.
6. Keep the backend on `Day5-starter`, which includes `POST /backups/restore`. A 404 on import usually means the wrong backend version is running.
7. Turn on Apple Intelligence for Task 1, the AI reliability check.
8. Verify that the application builds and connects to the backend.
9. Confirm that the supplied lab account can sign in.
10. Verify that OSV-Scanner, mobsfscan, and TruffleHog execute successfully.
11. Run the approved baseline scans and save the reports.
12. Confirm that the intended findings are present.
13. Prepare `Day5-final` as the instructor reference.
14. Rehearse the remediation and verification workflow.
15. Verify the backend backup and restore functionality.

#### Expected Behaviour

- All three scanners execute successfully.
- The starter produces the intended security findings.
- The backend supports the required lab workflow.
- The completed reference demonstrates the intended remediations.
- Scan reports can be saved for comparison and student evidence.

The supplied embedded token is a synthetic training fixture. Use only approved lab data and do not scan unrelated repositories or real credentials.

## 3. Delivery Readiness & Technical Support

### Backend Environment Verification

Backend-connected activities require a running local service.

For each applicable day, mentors should:

1. Confirm the approved backend repository, branch, and commit.
2. Prepare the required Python environment and dependencies.
3. Configure the supplied lab database and environment variables.
4. Start the backend on the designated host and port.
5. Verify the `/status` endpoint.
6. Confirm application connectivity and test-account authentication.
7. Keep the backend running throughout the relevant activity.

The Day 4 and Day 5 instructor guides specify different backend versions and lab databases. Do not assume that one backend configuration supports every workshop.

#### Example — Day 5 Backend

From the prepared backend directory:

    uv venv --python 3.12
    uv pip install --python .venv/bin/python -e '.[dev]'

Start the server:

    SEED_SAMPLE_DATA=true \
    DATABASE_URL=sqlite:///./day5-lab.db \
    .venv/bin/python -m uvicorn app.main:app \
      --host 127.0.0.1 --port 8000

Verify:

    curl -fsS http://127.0.0.1:8000/status

Use a separate Terminal session for the backend so it remains available during the workshop.

### Test Accounts and Configuration

Mentors should verify the required configurations before delivery.

| Configuration | Relevant Days | Verification |
|---|---|---|
| Hosted AI provider | Days 1 and 2 | Approved endpoint, model, and training key. Day 1: `ThirdPartyAIConfig.plist` (ignored by Git); the Day-2-server reference uses `LabAIConfig.swift` (tracked by Git). Day 2: the backend's `AI_ENDPOINT`, `AI_MODEL` and `AI_API_KEY` |
| Backend address | Days 2, 4, 5; Day 3 if required; the Day 1 Day-2-server reference | Correct local service URL |
| Lab account | Backend-connected days | Sign-in and sample data access |
| Apple Shortcuts and authentication | Day 2 | App Intent and authentication behaviour |
| Create ML datasets | Day 3 | Import, training, and evaluation |
| Apple Intelligence | Day 4 and Day 5 Task 1 | Compatible device and supported model functionality |
| Security scanning tools | Day 5 | Scanners execute and reports are generated |

Use fictional information throughout the program. Do not store real API keys, passwords, private tokens, or other sensitive credentials in GitHub, slides, screenshots, or student submissions.

### Workshop Materials

Before each workshop, confirm that the following are available:

| Material | Verification |
|---|---|
| Student starter application | Correct branch and successful build |
| Mentor reference application | Prepared separately and tested |
| Backend environment | Correct version and working connectivity |
| Student Daily Technical Setup | Instructions match the approved environment |
| Activity Brief and Workbook | Available and aligned with the activity |
| Instructor Guide | Reviewed, including timing and checkpoints |
| Presentation deck | Available and technically aligned |
| Datasets and supporting resources | Accessible where required |
| Test accounts and sample data | Working and appropriate for demonstrations |
| Troubleshooting notes | Known issues and workarounds documented |

### Technical Support and Escalation

Mentors should capture recurring technical problems, including:

- Software installation or compatibility issues
- GitHub access and branch problems
- Application build failures
- Backend connection or authentication failures
- Simulator and physical device limitations
- Hosted AI or Apple Intelligence availability
- Dataset import and model training errors
- Security scanner execution problems

Issues affecting multiple students or preventing progress should be escalated through the agreed technical support channels.

## Technical & Materials Readiness Checklist

#### Before Day 1

- [ ] Required development tools have been verified.
- [ ] GitHub repositories and application branches are accessible.
- [ ] Approved backend configurations have been identified.
- [ ] Student preparation materials have been distributed.
- [ ] Student installation and compatibility issues have been addressed.
- [ ] Instructor guides, presentation decks, and activity materials are available.

#### Before Each Workshop

- [ ] The correct student starter is prepared.
- [ ] The mentor reference is available.
- [ ] The application builds and launches.
- [ ] Backend connectivity works where required.
- [ ] Test accounts and supporting resources are available.
- [ ] Planned demonstrations have been rehearsed.
- [ ] Known technical issues and workarounds are documented.

#### After Each Workshop

- [ ] Technical issues and workarounds are recorded.
- [ ] Recurring student difficulties are captured.
- [ ] Student evidence requirements have been communicated.
- [ ] The next day's environment is prepared.
- [ ] Any issues affecting the next workshop have been escalated.

### Outstanding Technical Confirmations

The following items require confirmation before the guide is finalized:

1. Confirmed Nov 2: the Day 2 backend is `main`, at `9d18a42` or later.
2. Whether Day 3 requires a running backend and which version.
3. Confirmed Nov 2: Xcode 27.1, iOS 27 Simulator (iPhone 18 Pro), and an Apple silicon Mac on macOS 27.2 with Apple Intelligence on. Learners do not need an iPhone.
4. Still open: the length of the Day 5 Build, Test and Evaluate block (Day 5 guide, section 11).

