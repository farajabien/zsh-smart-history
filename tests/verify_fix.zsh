#!/usr/bin/env zsh

# Mock environment
HOME_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$HOME_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

# Source the plugin
source ./zsh-smart-history.plugin.zsh

# Multi-line command
original_cmd="example-command --task \"perform-sample-operation\" \\
  --url \"https://example.com/api\" \\
  --verbose --confirm"

echo "--- Simulating multi-line command execution ---"
_smart_history_preexec "$original_cmd"

echo "--- Checking the history file content ---"
# Should be exactly one line
line_count=$(wc -l < "$SMART_HISTORY_FILE" | tr -d ' ')
echo "Line count in log: $line_count"
if [[ "$line_count" -ne 1 ]]; then
  echo "FAILURE: Command should be stored as ONE line."
else
  echo "SUCCESS: Stored on one line."
fi
cat "$SMART_HISTORY_FILE"
echo ""

echo "--- Re-loading entries (decoding) ---"
# Clear state to force reload
_smart_cmd_freqs=()
_smart_cmd_recency=()
_smart_history_last_loaded_line=0
_smart_current_index=0

_smart_history_load_new_entries

echo "--- Verifying decoded command ---"
for k in "${(@k)_smart_cmd_freqs}"; do
  if [[ "$k" == "$original_cmd" ]]; then
    echo "SUCCESS: Command restored correctly including newlines!"
  else
    echo "FAILURE: Command mismatch!"
    echo "Expected: [$original_cmd]"
    echo "Got:      [$k]"
  fi
done

rm -rf "$HOME_DIR"
