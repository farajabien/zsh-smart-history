#!/bin/zsh

# Mock
zle() { :; }
add-zsh-hook() { :; }
bindkey() { :; }

# Setup data
TEST_DIR=$(mktemp -d)
export HOME="$TEST_DIR"
SMART_HISTORY_FILE="$HOME/.zsh_cmd_frequency_log"

logger() { echo "TEST LOG: $1"; }

# Source plugin
source "$1"

# Mock internal data
_smart_history_matches=("match1" "match2" "match3")
_smart_history_index=3
# current match is match3 (last one)

echo "Testing UP at boundary..."
# Simulate keypress UP when at MAX
LASTWIDGET="smart-history-up"
_smart_history_up
if (( _smart_history_index == 3 )); then
  echo "PASS: Up stopped at max index (3)"
else
  echo "FAIL: Up index changed to $_smart_history_index"
fi

echo "Testing DOWN at boundary..."
# Simulate keypress DOWN until 0
LASTWIDGET="smart-history-down"
_smart_history_down # index 2
echo "Index: $_smart_history_index"
_smart_history_down # index 1
echo "Index: $_smart_history_index"
_smart_history_down # index 0 (should be original buffer)
echo "Index: $_smart_history_index"

if (( _smart_history_index == 0 )); then
  echo "PASS: Down stopped at 0"
else
  echo "FAIL: Down index is $_smart_history_index"
fi

# Try go down one more time
_smart_history_down
if (( _smart_history_index == 0 )); then
  echo "PASS: Down stayed at 0"
else
  echo "FAIL: Down wrapped or changed to $_smart_history_index"
fi

rm -rf "$TEST_DIR"
