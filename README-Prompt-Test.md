# Day 1 prompt injection test

This branch completes the Anthropic connection from the Day 1 starter. The learner branch remains `Day-1-local`; the implemented demo is on `day1-prompt-injection`.

## Add the API key

From the repository folder, create the local configuration if it does not already exist:

```bash
cp -n "Dental Notes/ThirdPartyAIConfig.example.plist" "Dental Notes/ThirdPartyAIConfig.plist"
```

Open `Dental Notes/ThirdPartyAIConfig.plist` and replace only the `apiKey` value `REPLACE_WITH_YOUR_ANTHROPIC_API_KEY` with your training key. The example supplies the Anthropic Messages endpoint and `claude-haiku-4-5-20251001` model. Change the model there if your account needs a different one.

`ThirdPartyAIConfig.plist` is ignored by Git. The real key authenticates the HTTP request and is never inserted into the prompts.

`PromptSystem.md` contains a separate fake secret for the exercise:

```text
386620e9-c31f-4704-9cb4-e81dd7ebb4f6
```

Leave that fake value in the prompt. It is the value the attack tries to retrieve.

## Test without a phone

From this repository, run:

```bash
bash Scripts/test-day1-prompt.sh
```

The runner uses the same Swift HTTP client and prompt renderer as the app. It sends three separate requests from `Tests/PromptCases.json`: one ordinary note and two injection attempts. No previous reply is included in the next request.

For each reply it prints the returned model, request ID, stop reason, whether the exact dummy GUID appeared, whether the app can parse the draft, and the raw model text. A malformed JSON reply still appears in this report, so a parsing failure cannot hide a leaked GUID.

The supplied API-key placeholder stops the runner before any request. After adding a working key, each run sends three API requests. A refusal or no match is an observed result, not proof that other attacks cannot expose the value. The exact-match check does not detect encoded or partial disclosures.

To test the same notes with the fake configuration block removed from the outgoing system prompt:

```bash
bash Scripts/test-day1-prompt.sh --without-secret
```

This option changes the prompt in memory for that run and leaves the source file unchanged.

To test your own note, put it in a text file and run:

```bash
bash Scripts/test-day1-prompt.sh --note-file /path/to/note.txt
```

Keep the expected GUID out of the note itself. The runner rejects notes that already contain it.

## Test in the app

Open `Dental Notes.xcodeproj`, select the `Dental Notes` scheme and rebuild after changing the local configuration. This Day 1 test version uses the third-party provider.

Create a note using one of the examples in `Tests/PromptCases.json`, open it and choose **Process Note**. Inspect the summary and proposed follow-ups in the existing review screen. Nothing is applied to the note until you confirm.

If the reply is not valid note JSON, the app shows an error. Use the command-line runner to see that raw reply. The on-device Apple Intelligence activity remains unfinished.

## Offline checks

```bash
bash Tests/run-day1-checks.sh
```

These checks intercept every HTTP request and use made-up credentials and replies. They check prompt placement, authentication headers, JSON decoding and error handling. They do not establish whether a live Claude model will reveal the GUID.

API reference: [Anthropic Messages](https://platform.claude.com/docs/en/build-with-claude/working-with-messages) and [API overview](https://platform.claude.com/docs/en/api/overview).
