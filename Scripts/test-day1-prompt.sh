#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$repo_dir/build/day1-prompt-test"
mkdir -p "$build_dir"

xcrun swiftc -swift-version 5 -parse-as-library \
    -module-cache-path "$build_dir/module-cache" \
    "$repo_dir/Dental Notes/AIPromptTemplateLoader.swift" \
    "$repo_dir/Dental Notes/HostedAIClient.swift" \
    "$repo_dir/Tests/Day1PromptProbe.swift" \
    -o "$build_dir/prompt-probe"

"$build_dir/prompt-probe" "$repo_dir" "$@"
