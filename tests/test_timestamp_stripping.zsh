#!/usr/bin/env zsh

# Test Timestamp and Extended History Prefix Stripping

TEST_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$TEST_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

# Populate log file with various prefixed entries
echo "1785612651|pnpm dlx shadcn@latest add" >> "$SMART_HISTORY_FILE"
echo "1785612651|1785612651|pnpm dlx shadcn@latest add" >> "$SMART_HISTORY_FILE"
echo ": 1785612651:0;git status" >> "$SMART_HISTORY_FILE"
echo "1785612651|: 1785612651:0;npm test" >> "$SMART_HISTORY_FILE"

source ./zsh-smart-history.plugin.zsh

missing=0

check_cmd() {
  local cmd="$1"
  local expected_freq="$2"
  local freq="${_smart_cmd_freqs[$cmd]:-0}"
  if (( freq == expected_freq )); then
    echo "PASS: [$cmd] count is $freq"
  else
    echo "FAIL: [$cmd] count is $freq (expected $expected_freq)"
    (( missing++ ))
  fi
}

check_cmd "pnpm dlx shadcn@latest add" 2
check_cmd "git status" 1
check_cmd "npm test" 1

# Test preexec prefix stripping
_smart_history_preexec "1785612651|pnpm dlx shadcn@latest add"
check_cmd "pnpm dlx shadcn@latest add" 3

if (( missing == 0 )); then
  echo "SUCCESS: Timestamp and extended history prefixes stripped cleanly!"
else
  echo "FAILURE: Timestamp prefix leakage detected."
  rm -rf "$TEST_DIR"
  exit 1
fi

rm -rf "$TEST_DIR"
