#!/usr/bin/env python3

import json
import plistlib
import sys
import urllib.error
import urllib.request
from pathlib import Path


DEFAULT_CONFIG = (
    Path(__file__).resolve().parents[1]
    / "Dental Notes"
    / "ThirdPartyAIConfig.plist"
)


def read_error_message(response_body: bytes) -> str:
    try:
        payload = json.loads(response_body)
        return payload.get("error", {}).get("message", "Unknown Anthropic error")
    except (json.JSONDecodeError, AttributeError):
        return "Anthropic returned an unreadable error response"


def main() -> int:
    config_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_CONFIG

    try:
        with config_path.open("rb") as config_file:
            config = plistlib.load(config_file)
    except (OSError, plistlib.InvalidFileException) as error:
        print(f"Could not read {config_path}: {error}", file=sys.stderr)
        return 2

    api_key = str(config.get("apiKey", "")).strip()
    endpoint = str(config.get("endpoint", "")).strip()
    model = str(config.get("model", "")).strip()

    if not api_key or api_key.startswith("REPLACE_"):
        print("The plist does not contain a configured Anthropic API key.")
        return 2
    if endpoint != "https://api.anthropic.com/v1/messages":
        print("The plist endpoint is not the Anthropic Messages API.")
        return 2
    if not model:
        print("The plist does not contain a model name.")
        return 2

    request_body = json.dumps(
        {
            "model": model,
            "max_tokens": 1,
            "messages": [{"role": "user", "content": "Reply OK"}],
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        endpoint,
        data=request_body,
        method="POST",
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if response.status == 200:
                print(f"API key accepted. Anthropic completed a test request using {model}.")
                return 0
            print(f"Unexpected HTTP status: {response.status}")
            return 2
    except urllib.error.HTTPError as error:
        message = read_error_message(error.read())
        if error.code == 401:
            print(f"API key rejected by Anthropic: {message}")
            return 1
        print(f"Anthropic returned HTTP {error.code}: {message}")
        return 2
    except urllib.error.URLError as error:
        print(f"Could not reach Anthropic: {error.reason}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
