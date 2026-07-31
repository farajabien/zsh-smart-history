#!/usr/bin/env zsh

# Test smart_history_stats rendering, progress bar, counts in parentheses, and relative timestamps

TEST_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$TEST_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

source ./zsh-smart-history.plugin.zsh

now=$(date +%s)
ts_10m_ago=$(( now - 600 ))
ts_2h_ago=$(( now - 7200 ))
ts_3d_ago=$(( now - 259200 ))

# Populate log with timestamped history entries
echo "${ts_3d_ago}|git checkout main" >> "$SMART_HISTORY_FILE"
echo "${ts_2h_ago}|npm run dev" >> "$SMART_HISTORY_FILE"
echo "${ts_2h_ago}|npm run dev" >> "$SMART_HISTORY_FILE"
echo "${ts_10m_ago}|git status" >> "$SMART_HISTORY_FILE"
echo "${ts_10m_ago}|git status" >> "$SMART_HISTORY_FILE"
echo "${ts_10m_ago}|git status" >> "$SMART_HISTORY_FILE"

# Trigger load
_smart_history_load_new_entries

echo "--- Testing smart_history_stats output ---"
output=$(smart_history_stats)
echo "$output"

echo "\n--- Validating formatting requirements ---"
failures=0

# Check header
if [[ "$output" == *"All Commands Ranked by Usage"* ]]; then
  echo "PASS: Table header present"
else
  echo "FAIL: Missing header"
  (( failures++ ))
fi

# Check progress bar formatting [===...]
if [[ "$output" == *"["*"="*"]"* ]]; then
  echo "PASS: Progress bar displayed"
else
  echo "FAIL: Missing progress bar"
  (( failures++ ))
fi

# Check counts in parentheses e.g. (3)
if [[ "$output" =~ '\(3\)' && "$output" =~ '\(2\)' && "$output" =~ '\(1\)' ]]; then
  echo "PASS: Counts in parentheses format (N) verified"
else
  echo "FAIL: Parentheses count formatting incorrect"
  (( failures++ ))
fi

# Check percentage e.g. (50.0%)
if [[ "$output" =~ '\(50\.0%\)' ]]; then
  echo "PASS: Percentage format (XX.X%) verified"
else
  echo "FAIL: Percentage formatting incorrect"
  (( failures++ ))
fi

# Check relative timestamps (10m ago, 2h ago, 3d ago)
if [[ "$output" == *"10m ago"* && "$output" == *"2h ago"* && "$output" == *"3d ago"* ]]; then
  echo "PASS: Relative timestamps (xx ago) verified"
else
  echo "FAIL: Relative timestamp calculations incorrect"
  (( failures++ ))
fi

rm -rf "$TEST_DIR"

if (( failures == 0 )); then
  echo "\nSUCCESS: All stats widget formatting requirements met!"
else
  echo "\nFAILURE: $failures formatting assertions failed."
  exit 1
fi
