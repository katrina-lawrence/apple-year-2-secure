
# Year 2 Cybersecurity Program

**Mentor Training & Module 1 Delivery Guide**

---

# Purpose of This Document

This guide serves two complementary purposes:

## 1. Mentor Preparation & Training Framework

Provides a structured approach to preparing mentors to support the cybersecurity program. It outlines the knowledge, technical preparation, facilitation skills, and resources needed to guide learners through the Challenge-Based Learning (CBL) experience.

The goal is to ensure mentors understand the learning journey, can confidently support hands-on activities, troubleshooting, testing, and reflection, and encourage independent problem-solving while maintaining learner ownership.

## 2. Module 1: Specific Guidance & Resources

Provides practical guidance to prepare mentors for Year 2, Module 1, including learning objectives, challenge activities, technical setup, demonstrations, expected outcomes, troubleshooting, and supporting resources.

This section serves as a reference for mentors before, during, and after delivery, helping them effectively support learners and collaborate with the instructional team.

---

# Module 1 Mentor Delivery Guide

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
