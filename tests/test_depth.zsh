#!/usr/bin/env zsh

# Mock environment
HOME_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$HOME_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

# Source the plugin
source ./zsh-smart-history.plugin.zsh

echo "--- Generating 17 unique multi-line commands ---"
for i in {1..17}; do
  cmd="cmd-number-$i --option \"value-$i\" \\
  --multi-line \\
  --index $i"
  _smart_history_preexec "$cmd"
done

echo "--- Checking history file line count ---"
# Each command should be exactly one line
count=$(wc -l < "$SMART_HISTORY_FILE" | tr -d ' ')
echo "Stored commands in file: $count"

if [[ "$count" -eq 17 ]]; then
  echo "SUCCESS: All 17 commands stored as single lines."
else
  echo "FAILURE: Expected 17 lines, got $count."
fi

echo "--- Verifying restoration of all 17 commands ---"
_smart_history_load_new_entries

# Check frequencies map size
map_size=${#_smart_cmd_freqs}
echo "Commands in memory: $map_size"

if [[ "$map_size" -eq 17 ]]; then
  echo "SUCCESS: All 17 commands loaded into memory correctly."
else
  echo "FAILURE: Expected 17 commands in memory, got $map_size."
fi

# Verify a few specific ones
for i in 1 9 17; do
  expected="cmd-number-$i --option \"value-$i\" \\
  --multi-line \\
  --index $i"
  
  if [[ -n "${_smart_cmd_freqs[$expected]}" ]]; then
    echo "SUCCESS: Found correctly decoded command #$i"
  else
    echo "FAILURE: Command #$i missing or incorrectly decoded!"
  fi
done

rm -rf "$HOME_DIR"
