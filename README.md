# My Dental Companion: Day 2 starter

This branch is the learner starting point for Day 2. It deliberately stores session tokens in UserDefaults and includes a provider API key placeholder in the app. The Create Follow-up intent is registered but unfinished.

See [README-Day-2.md](README-Day-2.md) for the build activity and the three security tasks.

## Run the app

1. Start `catalyst-server` using its README. Its default port is 8000.
2. Copy `Dental Notes/BackendConfig.example.plist` to `Dental Notes/BackendConfig.plist`. For an iPhone Simulator on the same Mac, use `http://127.0.0.1:8000`. For a physical iPhone, use the Mac's reachable network address and the classroom network setup; `127.0.0.1` on the phone points to the phone itself.
3. Open `Dental Notes.xcodeproj` and select the `Dental Notes Server` scheme. The app targets iOS 26.2 or later.
4. Run the app and create or sign into a test account. Notes and follow-ups are stored on the backend, with an in-memory SwiftData copy in the app.
5. In `Dental Notes/LabAIConfig.swift`, replace the placeholder with your training API key. Rebuild, open a made-up note, and choose **Process Note**. The starter calls Anthropic directly and lets you review the result before saving it.

The placeholder cannot authenticate a provider request. Until you replace it, the app shows a setup message. Keep your real key local and restore the placeholder before committing or sharing code. The default model can be changed in the same file to the model agreed for the class.

The app still uses the backend for login, notes and follow-ups. During the security task, learners also move AI processing to the backend. Apple Intelligence and note classification are later activities.

`BackendConfig.plist` is ignored by Git. Opening this branch after another version may require a fresh login because this starter reads its own UserDefaults token keys.

## Checks

Run `bash Tests/run-day2-checks.sh` on a Mac with Xcode command-line tools. These checks use fake credentials and intercepted HTTP responses; they do not call Anthropic or the classroom backend.

Build the iOS app using Xcode. Rehearse the completed intent on a passcode-protected physical device to check locked-device behaviour.
