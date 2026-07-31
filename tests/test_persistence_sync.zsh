#!/usr/bin/env zsh

# Test Multi-Terminal History Persistence and Real-Time Synchronization

TEST_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$TEST_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

echo "--- Initializing Terminal A ---"
# Source plugin for Session A
source ./zsh-smart-history.plugin.zsh

# Session A runs 2 commands
_smart_history_preexec "git status"
_smart_history_preexec "npm test"

echo "--- Simulating Terminal B executing commands in background ---"
# Simulate Terminal B appending to SMART_HISTORY_FILE directly (with timestamp)
now=$(date +%s)
echo "${now}|docker ps" >> "$SMART_HISTORY_FILE"
echo "${now}|git commit -m \"update\"" >> "$SMART_HISTORY_FILE"
echo "${now}|npm test" >> "$SMART_HISTORY_FILE"

echo "--- Terminal A executes a new command ---"
# Terminal A runs another command - should auto-sync Terminal B's entries BEFORE writing!
_smart_history_preexec "ls -la"

echo "--- Verifying Terminal A's loaded commands ---"
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

check_cmd "git status" 1
check_cmd "npm test" 2
check_cmd "docker ps" 1
check_cmd "git commit -m \"update\"" 1
check_cmd "ls -la" 1

total_lines=$(wc -l < "$SMART_HISTORY_FILE" | tr -d ' ')
echo "Total lines in log file: $total_lines"
echo "Last loaded line index: $_smart_history_last_loaded_line"

if (( total_lines == _smart_history_last_loaded_line && missing == 0 )); then
  echo "SUCCESS: All multi-terminal commands persisted and synchronized cleanly without loss!"
else
  echo "FAILURE: Command loss or desync detected."
  rm -rf "$TEST_DIR"
  exit 1
fi

rm -rf "$TEST_DIR"
