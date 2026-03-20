#!/usr/bin/env bash
# UserPromptSubmit hook: block sensitive data (SSN, DOB) in user input
# Reads event JSON from stdin. Exit 2 = block, Exit 0 = allow.
set -euo pipefail

INPUT=$(cat)

# Extract the user's prompt text from the event JSON
# UserPromptSubmit schema: { "session_id": "...", "prompt": "user text here", ... }
USER_TEXT=$(echo "$INPUT" | jq -r '.prompt // .tool_input.content // .tool_input // ""' 2>/dev/null || echo "")

if [ -z "$USER_TEXT" ]; then
  exit 0
fi

# SSN pattern: XXX-XX-XXXX (with dashes)
if printf '%s\n' "$USER_TEXT" | grep -qP '\b\d{3}-\d{2}-\d{4}\b' 2>/dev/null; then
  echo "BLOCKED: For your security, please do not share your Social Security number in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application." >&2
  exit 2
fi

# SSN pattern: XXX XX XXXX (with spaces)
if printf '%s\n' "$USER_TEXT" | grep -qP '\b\d{3}\s\d{2}\s\d{4}\b' 2>/dev/null; then
  echo "BLOCKED: For your security, please do not share your Social Security number in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application." >&2
  exit 2
fi

# 9 consecutive digits (SSN without separators) — exclude common non-SSN patterns
if printf '%s\n' "$USER_TEXT" | grep -qP '(?<!\d)(?<!#)\b\d{9}\b(?!\d)' 2>/dev/null; then
  # Exclude if preceded by contextual words that indicate non-SSN
  if ! printf '%s\n' "$USER_TEXT" | grep -qiP '(account|routing|phone|zip|nmls|#)\s*\d{9}' 2>/dev/null; then
    echo "BLOCKED: For your security, please do not share your Social Security number in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application." >&2
    exit 2
  fi
fi

# DOB patterns: only match when contextual keywords are present
if printf '%s\n' "$USER_TEXT" | grep -qiP '(date\s*of\s*birth|d\.?o\.?b\.?|born\s*(on|in)?|my\s*birthday)\s*(?:is|was|[:=])?\s*\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}' 2>/dev/null; then
  echo "BLOCKED: For your security, please do not share your date of birth in this chat. This information will be collected securely through LendTrain's encrypted portal when you submit a formal application." >&2
  exit 2
fi

# Allow the message
exit 0
