
# Year 2 — Student Daily Technical Setup

This guide provides the technical setup instructions for each workshop day.

Complete the setup for the relevant day with your mentor before beginning the activities.

## Daily Technical Setup

### Day 1 — Hosted AI and Prompt Injection

**Application branch:** `Day-1-local`

1. Download or open the approved Day 1 starter application.
2. Open `Dental Notes.xcodeproj` in Xcode.
3. Select the `Dental Notes` scheme and an approved iPhone Simulator.
4. Build and launch the application.
5. Confirm that local dental notes can be created and reopened.
6. Follow your mentor's instructions to prepare `ThirdPartyAIConfig.plist` using the supplied example.
7. Confirm that the approved AI provider configuration is available.

**Ready when:** The starter application runs and the local note workflow works. The hosted AI implementation is intentionally incomplete.

### Day 2 — Secure Architecture and Platform Protections

**Application branch:** `Day-2-server`  
**Backend:** Mentor-approved version

1. Open the approved Day 2 application.
2. Prepare and start the backend using your mentor's instructions.
3. Confirm that `http://127.0.0.1:8000/status` responds successfully.
4. Verify the backend address in `BackendConfig.plist`.
5. Select the `Dental Notes Server` scheme.
6. Launch the application and sign in with the supplied test account.
7. Confirm that Apple Shortcuts are available.

**Ready when:** The application launches, connects to the backend, and supports test-account login.

### Day 3 — Create ML and Text Classification

**Application branch:** `Day-3-server`

1. Open the approved Day 3 application and clone it locally.
2. Download the supplied training and testing datasets.
3. Open the datasets in Apple Numbers.
4. Confirm that Create ML is available.
5. Prepare separate folders for datasets, model files, and activity evidence.
6. Launch the starter application using your mentor's instructions.

**Ready when:** The datasets can be opened, Create ML is available, and the approved application starter runs.

Do not clean the datasets or train the final model before the activity.

### Day 4 — On-Device AI and Application Security

**Application branch:** `Day-4`  
**Backend branch:** `main`

1. Open the approved Day 4 application and backend.
2. Start the local backend using the provided instructions.
3. Confirm that the application can connect to the backend.
4. Select the `Dental Notes Server` scheme.
5. Launch the application and sign in.
6. Confirm that the required Apple Intelligence environment is available.

**Ready when:** The application runs, the backend is connected, and the on-device AI environment has been checked.

The starter's incomplete functionality and security weaknesses are part of the workshop.

### Day 5 — Security Scanning and Remediation

**Application branch:** `Day5-starter`  
**Backend branch:** `Day5-starter`

1. Open the approved Day 5 application and backend.
2. Start the backend using the provided instructions.
3. Confirm that the backend responds at `/status`.
4. Build and launch the application.
5. Confirm that OSV-Scanner, mobsfscan, and TruffleHog are available.
6. Create a folder for storing scan reports.
7. Keep the starter code unchanged until the activity begins.

**Ready when:** The application and backend are running and all three security scanners are available.

## Daily Student Checklist

At the beginning of each workshop, confirm:

- [ ] The correct starter application is open.
- [ ] The required development tools are available.
- [ ] Any required backend is running.
- [ ] Activity materials are accessible.
- [ ] The application launches successfully.
- [ ] Technical issues have been reported to the mentor.

[Back to Student Resources](README.md)
