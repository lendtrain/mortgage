#!/usr/bin/env bash
# UserPromptSubmit hook: block sensitive data (SSN, DOB) in user input
# Reads event JSON from stdin. Exit 2 = block, Exit 0 = allow.
# Compatible with macOS (BSD grep) and Windows (Git Bash) — uses grep -E only.
set -euo pipefail

INPUT=$(cat)

# Extract the user's prompt text from the event JSON
# UserPromptSubmit schema: { "session_id": "...", "prompt": "user text here", ... }
USER_TEXT=$(echo "$INPUT" | jq -r '.prompt // .tool_input.content // .tool_input // ""' 2>/dev/null || echo "")

if [ -z "$USER_TEXT" ]; then
  exit 0
fi

BLOCK_SSN="BLOCKED: For your security, please do not share your Social Security number in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application."
BLOCK_DOB="BLOCKED: For your security, please do not share your date of birth in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application."

# SSN pattern: XXX-XX-XXXX (with dashes)
if printf '%s\n' "$USER_TEXT" | grep -Eq '[0-9]{3}-[0-9]{2}-[0-9]{4}'; then
  echo "$BLOCK_SSN" >&2
  exit 2
fi

# SSN pattern: XXX XX XXXX (with spaces)
if printf '%s\n' "$USER_TEXT" | grep -Eq '[0-9]{3}[[:space:]][0-9]{2}[[:space:]][0-9]{4}'; then
  echo "$BLOCK_SSN" >&2
  exit 2
fi

# 9 consecutive digits (SSN without separators) — exclude common non-SSN patterns
if printf '%s\n' "$USER_TEXT" | grep -Eq '[0-9]{9}'; then
  # Exclude if preceded by contextual words that indicate non-SSN
  if ! printf '%s\n' "$USER_TEXT" | grep -Eiq '(account|routing|phone|zip|nmls|#)[[:space:]]*[0-9]{9}'; then
    echo "$BLOCK_SSN" >&2
    exit 2
  fi
fi

# DOB patterns: only match when contextual keywords are present
if printf '%s\n' "$USER_TEXT" | grep -Eiq '(date[[:space:]]*of[[:space:]]*birth|d\.?o\.?b\.?|born[[:space:]]*(on|in)?|my[[:space:]]*birthday)[[:space:]]*(is|was|[=:])?[[:space:]]*[0-9]{1,2}[/.\-][0-9]{1,2}[/.\-][0-9]{2,4}'; then
  echo "$BLOCK_DOB" >&2
  exit 2
fi

# Allow the message
exit 0
