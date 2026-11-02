
# Year 2 — Student Technical Preparation

Before the program begins, you must prepare your development environment for five consecutive days of iOS application development and security activities.

You will use the My Dental Companion application, supporting backend services, Apple development tools, and security testing utilities.

All required software should be installed and verified before Day 1. Daily application setup and activity-specific configuration will be completed with mentor guidance during the workshops.

## Required Software

| Tool | Purpose | Preparation |
|---|---|---|
| Xcode | Build and test the iOS application | Install before Day 1 |
| iPhone Simulator | Run the application | Install before Day 1 |
| Git | Access application repositories | Verify before Day 1 |
| Terminal | Run development commands | Available on macOS |
| Homebrew | Install development utilities | Install before Day 1 |
| Python 3.12 | Run backend services | Install before Day 1 |
| uv | Manage Python environments | Install before Day 1 |
| Apple Numbers | Prepare and review datasets | Install before Day 1 |
| Create ML | Train and evaluate classification models | Verify availability before Day 1 |
| OSV-Scanner | Dependency vulnerability scanning | Install before Day 1 |
| mobsfscan | Source-code security scanning | Install before Day 1 |
| TruffleHog | Secret detection | Install before Day 1 |
| Apple Shortcuts | App Intents activities | Verify availability before Day 1 |

## Install and Verify Development Tools

### Step 1 — Prepare Xcode

1. Install the approved version of Xcode.
2. Launch Xcode and complete its initial setup.
3. Install a compatible iPhone Simulator through Xcode Settings → Components.
4. Confirm that the Simulator launches successfully.
5. Verify that Xcode can create and run a basic iOS project.

### Step 2 — Prepare Command-Line Tools

Open Terminal and confirm that Git and Xcode are available:

```bash
git --version
xcodebuild -version
xcrun simctl list devices available
```

Install Homebrew if it is not already available, following the instructions at [brew.sh](https://brew.sh).

Install the required utilities:

```bash
brew install uv osv-scanner trufflehog
uv python install 3.12
```

Prepare mobsfscan:

```bash
uv tool run --python 3.12 \
  --from mobsfscan==1.0.1 \
  mobsfscan --version
```

Verify the installations:

```bash
uv --version
osv-scanner --version
trufflehog --version
```

### Step 3 — Prepare Apple Development Tools

1. Confirm that Apple Numbers can open CSV files.
2. Confirm that Create ML is available.
3. Verify that Apple Shortcuts is available on the intended test device or Simulator.
4. Check whether your Mac or approved device supports the Apple Intelligence features required for Day 4.
5. Notify your mentor if your environment does not support the required features.

## GitHub Access

You will work with two repositories:

| Repository | Purpose |
|---|---|
| [apple-year-2-secure](https://github.com/katrina-lawrence/apple-year-2-secure) | My Dental Companion iOS application |
| [apple-year-2-backend](https://github.com/katrina-lawrence/apple-year-2-backend) | Supporting backend services |

Before Day 1:

1. Confirm that you can open both repositories.
2. Verify that Git can access the repositories.
3. Do not download or modify completed reference implementations.
4. Wait for your mentor to identify the correct application branch for each day.

## Student Materials

Confirm that you have received:

- Program overview and schedule
- Activity Briefs
- [Student Activity Workbook](student-activity-workbook.md)
- Technical preparation instructions
- Required supporting resources
- Instructions for reporting technical issues

Day-specific datasets, configuration details, and starter application instructions will be provided by your mentor.

## Pre-Program Readiness Checklist

- [ ] Xcode is installed and launches successfully.
- [ ] A compatible iPhone Simulator is available.
- [ ] Git and Terminal are working.
- [ ] Homebrew, Python 3.12, and `uv` are available.
- [ ] Apple Numbers and Create ML are available.
- [ ] Apple Shortcuts is available.
- [ ] OSV-Scanner, mobsfscan, and TruffleHog are installed.
- [ ] Apple Intelligence compatibility has been checked.
- [ ] Both GitHub repositories are accessible.
- [ ] Program materials have been received.

**Important:** Do not begin the daily challenges or modify the starter applications before the workshops. Your mentor will guide you through the required setup at the beginning of each day.

[Back to Student Resources](README.md)
