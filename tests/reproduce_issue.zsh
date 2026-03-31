#!/usr/bin/env zsh

# Mock environment
HOME_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$HOME_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

# Source the plugin
source ./zsh-smart-history.plugin.zsh

# Mock preexec for a multi-line command
multi_line_cmd="example-command --task \"perform-sample-operation\" \\
  --url \"https://example.com/api\" \\
  --message \"Test message for multi-line support verification.\" \\
  --email \"user@example.test\" \\
  --id \"123456\" \\
  --verbose --confirm"

echo "--- Simulating multi-line command execution ---"
_smart_history_preexec "$multi_line_cmd"

echo "--- Checking the history file content ---"
cat "$SMART_HISTORY_FILE"
echo "\n--- End of history file ---"

echo "--- Re-loading entries (simulating new shell or update) ---"
# Clear current state to force reload
_smart_cmd_freqs=()
_smart_cmd_recency=()
_smart_history_last_loaded_line=0
_smart_current_index=0

_smart_history_load_new_entries

echo "--- Checking loaded frequencies ---"
for k in "${(@k)_smart_cmd_freqs}"; do
  echo "Cmd: [$k] Freq: ${_smart_cmd_freqs[$k]}"
done

rm -rf "$HOME_DIR"
