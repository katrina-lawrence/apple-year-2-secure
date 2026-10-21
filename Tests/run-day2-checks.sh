#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/day2-checks.XXXXXX")"
suite="org.appleacademy.day2.checks.$(basename "$check_dir")"
cleanup() {
    if [ -x "$check_dir/checks" ]; then
        "$check_dir/checks" --clear-tokens "$suite" >/dev/null 2>&1 || true
    fi
    rm -rf "$check_dir"
}
trap cleanup EXIT

mkdir -p "$check_dir/Prompts.bundle"
cp "$repo_dir/Dental Notes/PromptSystem.md" "$repo_dir/Dental Notes/PromptUser.md" "$check_dir/Prompts.bundle/"
cat > "$check_dir/Prompts.bundle/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>org.appleacademy.day2.testprompts</string></dict></plist>
PLIST

xcrun swiftc -swift-version 5 -parse-as-library \
    -module-cache-path "$check_dir/module-cache" \
    "$repo_dir/Dental Notes/AIModels.swift" \
    "$repo_dir/Dental Notes/LabAIConfig.swift" \
    "$repo_dir/Dental Notes/HostedAIClient.swift" \
    "$repo_dir/Dental Notes/SessionTokenStore.swift" \
    "$repo_dir/Tests/Day2StarterChecks.swift" \
    -o "$check_dir/checks"

"$check_dir/checks" --write-tokens "$suite"
"$check_dir/checks" --read-tokens "$suite"
"$check_dir/checks" --clear-tokens "$suite"
"$check_dir/checks" --verify-cleared "$suite"
"$check_dir/checks" "$check_dir/Prompts.bundle"
