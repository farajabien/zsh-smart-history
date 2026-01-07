# Smart Frequency-Based History for Zsh
# https://github.com/yourusername/zsh-smart-history
#
# A Zsh plugin that overrides the Up key to search history by FREQUENCY.
#
# Installation: Source this file in your .zshrc
# See README.md for full instructions.

# --- Configuration ---
SMART_HISTORY_FILE="$HOME/.zsh_cmd_frequency_log"
typeset -A _smart_cmd_freqs

# --- 1. Frequency Tracking ---

# Load existing frequencies on startup
if [[ -f "$SMART_HISTORY_FILE" ]]; then
  # Simple parsing: specific implementation may vary, strictly dependent on file format.
  # Here we assume simpler line-by-line log for robustness, calculated on load.
  # Optimization: You might want to compact this log file periodically.
  while read -r line; do
    # Use 'let' with quoting to safely handle special chars in keys
    let "_smart_cmd_freqs[\$line]++"
  done < "$SMART_HISTORY_FILE"
fi

_smart_history_preexec() {
  local cmd="$1"
  # Trim whitespace
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  cmd="${cmd%"${cmd##*[![:space:]]}"}"
  
  if [[ -n "$cmd" ]]; then
    # Update memory
    (( _smart_cmd_freqs[$cmd]++ ))
    # Persist to log (append only for speed)
    print -r -- "$cmd" >> "$SMART_HISTORY_FILE"
  fi
}

add-zsh-hook preexec _smart_history_preexec

# --- 2. Smart Search Widget ---

_smart_history_matches=()
_smart_history_index=0
_smart_history_original_buffer=""

_smart_history_up() {
  # If we are continuing a search...
  if [[ $LASTWIDGET == "smart-history-up" ]]; then
    (( _smart_history_index++ ))
    if (( _smart_history_index > $#_smart_history_matches )); then
       _smart_history_index=1 # Cycle back to top? Or stop? Let's cycle.
    fi
    BUFFER="${_smart_history_matches[$_smart_history_index]}"
    CURSOR=$#BUFFER
    return
  fi

  # Start a new search
  _smart_history_original_buffer="$BUFFER"
  _smart_history_index=1 # 1-based index for zsh arrays
  _smart_history_matches=()

  # 1. Identify candidates matching the current buffer prefix
  local prefix="$BUFFER"
  local -A candidates
  
  # We search both our frequency DB AND the zsh history
  # Merge them: frequency DB gives us the ranks, zsh history gives us recents.
  # The requirement is "Rank by frequency".
  # So we iterate over our _smart_cmd_freqs keys.
  
  local -a scored_cmds
  for cmd count in "${(@kv)_smart_cmd_freqs}"; do
    if [[ "$cmd" == "$prefix"* ]]; then
      # Format: "count:cmd" for sorting
      scored_cmds+=("$count:$cmd")
    fi
  done

  # Also include current history if not in DB (with count 0)?
  # For simplicity, we rely on the DB which fills up as we work. 
  # But to be useful immediately, we might want to grab recent history.
  # Implementing "Hybrid" is complex. Let's stick to the requested "Analytics" approach.
  # Note: The tool will learn as you type.
  
  if [[ ${#scored_cmds} -eq 0 ]]; then
     zle up-line-or-history
     return
  fi

  # 2. Sort by frequency (numeric descending)
  # (On) flags: O = descending, n = numeric
  local -a sorted_scored
  sorted_scored=("${(@On)scored_cmds}")

  # 3. Strip the scores to get clean commands (remove leading 'digits:')
  _smart_history_matches=("${sorted_scored[@]#[0-9]*:}")

  # 4. Apply first match
  if [[ ${#_smart_history_matches} -ge 1 ]]; then
    BUFFER="${_smart_history_matches[1]}"
    CURSOR=$#BUFFER
  else
    # Fallback if logic matches nothing (shouldn't happen given check above)
    zle up-line-or-history
  fi
}

# Define the widget
zle -N smart-history-up _smart_history_up

# --- 3. Key Bindings ---
# Bind to Up Arrow. 
# Note: Key codes vary (`^[[A` is standard for xterm/mac terminal).
bindkey '^[[A' smart-history-up
bindkey '^P' smart-history-up
