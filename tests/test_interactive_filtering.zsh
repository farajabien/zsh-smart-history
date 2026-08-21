#!/usr/bin/env zsh

# Test Up/Down Interactive History Filtering & Scoping Behavior
# Tests:
# 1. Blank prompt + Up arrow (navigates recent commands normally)
# 2. Typed characters + Up arrow (scopes only to matching commands)
# 3. Multiple Up presses (cycles through filtered candidates ranked by score)
# 4. Down arrow navigation (steps back down through filtered matches)
# 5. Down to index 0 (restores original typed text)
# 6. Fuzzy / case-insensitive search scoping

# Mock ZLE functions if not in interactive terminal
zle() {
  local widget="$1"
  if [[ "$widget" == "up-line-or-history" ]]; then
    MOCK_FALLBACK_CALLED="up-line-or-history"
  elif [[ "$widget" == "down-line-or-history" ]]; then
    MOCK_FALLBACK_CALLED="down-line-or-history"
  fi
}
add-zsh-hook() { :; }
bindkey() { :; }

TEST_DIR=$(mktemp -d)
SMART_HISTORY_FILE="$TEST_DIR/.zsh_cmd_frequency_log"
export SMART_HISTORY_FILE

source ./zsh-smart-history.plugin.zsh

now=$(date +%s)
# Seed history with varied commands and frequencies
# Most recent and frequent: git status (freq 4), git commit -m "fix" (freq 2), git diff (freq 1)
# docker compose up (freq 3), docker ps (freq 1)
# npm run build (freq 5), npm test (freq 2)
# echo "hello world" (freq 1)

echo "$(( now - 100 ))|echo \"hello world\"" >> "$SMART_HISTORY_FILE"
echo "$(( now - 90 ))|docker ps" >> "$SMART_HISTORY_FILE"
echo "$(( now - 80 ))|git diff" >> "$SMART_HISTORY_FILE"
echo "$(( now - 70 ))|npm test" >> "$SMART_HISTORY_FILE"
echo "$(( now - 60 ))|npm test" >> "$SMART_HISTORY_FILE"
echo "$(( now - 50 ))|git commit -m \"fix\"" >> "$SMART_HISTORY_FILE"
echo "$(( now - 45 ))|git commit -m \"fix\"" >> "$SMART_HISTORY_FILE"
echo "$(( now - 40 ))|docker compose up" >> "$SMART_HISTORY_FILE"
echo "$(( now - 35 ))|docker compose up" >> "$SMART_HISTORY_FILE"
echo "$(( now - 30 ))|docker compose up" >> "$SMART_HISTORY_FILE"
echo "$(( now - 25 ))|git status" >> "$SMART_HISTORY_FILE"
echo "$(( now - 20 ))|git status" >> "$SMART_HISTORY_FILE"
echo "$(( now - 15 ))|git status" >> "$SMART_HISTORY_FILE"
echo "$(( now - 10 ))|git status" >> "$SMART_HISTORY_FILE"
echo "$(( now - 5 ))|npm run build" >> "$SMART_HISTORY_FILE"
echo "$(( now - 4 ))|npm run build" >> "$SMART_HISTORY_FILE"
echo "$(( now - 3 ))|npm run build" >> "$SMART_HISTORY_FILE"
echo "$(( now - 2 ))|npm run build" >> "$SMART_HISTORY_FILE"
echo "$(( now - 1 ))|npm run build" >> "$SMART_HISTORY_FILE"

# Trigger load
_smart_history_load_new_entries

failures=0

echo "=== TEST 1: Blank Buffer (Pressing Up with empty prompt) ==="
BUFFER=""
LASTWIDGET=""
_smart_history_up

if [[ "$BUFFER" == "npm run build" ]]; then
  echo "PASS: Blank buffer returns most recent command ('npm run build')"
else
  echo "FAIL: Expected 'npm run build', got '$BUFFER'"
  (( failures++ ))
fi

# Press Up again to continue blank history search
LASTWIDGET="smart-history-up"
_smart_history_up
if [[ "$BUFFER" == "git status" ]]; then
  echo "PASS: Second Up returns next most recent command ('git status')"
else
  echo "FAIL: Expected 'git status', got '$BUFFER'"
  (( failures++ ))
fi


echo "\n=== TEST 2: Scoped Search (Typing 'git' + Pressing Up) ==="
BUFFER="git"
LASTWIDGET=""
_smart_history_up

if [[ "$BUFFER" == "git status" ]]; then
  echo "PASS: 'git' scopes to highest ranked git command ('git status')"
else
  echo "FAIL: Expected 'git status', got '$BUFFER'"
  (( failures++ ))
fi

# Press Up again to cycle through 'git' matches
LASTWIDGET="smart-history-up"
_smart_history_up
if [[ "$BUFFER" == "git commit -m \"fix\"" ]]; then
  echo "PASS: Second Up gives next git match ('git commit -m \"fix\"')"
else
  echo "FAIL: Expected 'git commit -m \"fix\"', got '$BUFFER'"
  (( failures++ ))
fi

LASTWIDGET="smart-history-up"
_smart_history_up
if [[ "$BUFFER" == "git diff" ]]; then
  echo "PASS: Third Up gives ('git diff')"
else
  echo "FAIL: Expected 'git diff', got '$BUFFER'"
  (( failures++ ))
fi


echo "\n=== TEST 3: Down Navigation Back to Default / Original Input ==="
# Press Down from 'git diff' (index 3 -> 2)
LASTWIDGET="smart-history-down"
_smart_history_down
if [[ "$BUFFER" == "git commit -m \"fix\"" ]]; then
  echo "PASS: Down moved back to index 2 ('git commit -m \"fix\"')"
else
  echo "FAIL: Expected 'git commit -m \"fix\"', got '$BUFFER'"
  (( failures++ ))
fi

# Press Down (index 2 -> 1)
_smart_history_down
if [[ "$BUFFER" == "git status" ]]; then
  echo "PASS: Down moved back to index 1 ('git status')"
else
  echo "FAIL: Expected 'git status', got '$BUFFER'"
  (( failures++ ))
fi

# Press Down (index 1 -> 0: restore original input)
_smart_history_down
if [[ "$BUFFER" == "git" && $_smart_history_index -eq 0 ]]; then
  echo "PASS: Down restored original typed buffer ('git') at index 0"
else
  echo "FAIL: Expected BUFFER='git' and index 0, got BUFFER='$BUFFER' and index $_smart_history_index"
  (( failures++ ))
fi


echo "\n=== TEST 4: Fuzzy Search Scoping (Typing 'dc' for docker compose) ==="
BUFFER="dc"
LASTWIDGET=""
_smart_history_up
if [[ "$BUFFER" == "docker compose up" ]]; then
  echo "PASS: 'dc' fuzzy matched and scoped to 'docker compose up'"
else
  echo "FAIL: Expected 'docker compose up', got '$BUFFER'"
  (( failures++ ))
fi


echo "\n=== TEST 5: Non-matching search fallback ==="
MOCK_FALLBACK_CALLED=""
BUFFER="nonexistentcommand12345"
LASTWIDGET=""
_smart_history_up
if [[ "$MOCK_FALLBACK_CALLED" == "up-line-or-history" ]]; then
  echo "PASS: Non-matching term fell back to standard zle up-line-or-history"
else
  echo "FAIL: Expected fallback to up-line-or-history, got '$MOCK_FALLBACK_CALLED'"
  (( failures++ ))
fi

rm -rf "$TEST_DIR"

if (( failures == 0 )); then
  echo "\nSUCCESS: All Up/Down filtering and scoping tests passed cleanly!"
  exit 0
else
  echo "\nFAILURE: $failures tests failed."
  exit 1
fi
