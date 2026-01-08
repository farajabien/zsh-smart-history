# Smart Frequency-Based History for Zsh
# https://github.com/yourusername/zsh-smart-history
#
# A Zsh plugin that overrides the Up key to search history by FREQUENCY then RECENCY.
#
# Installation: Source this file in your .zshrc
# See README.md for full instructions.

# --- Configuration ---
SMART_HISTORY_FILE="$HOME/.zsh_cmd_frequency_log"
typeset -A _smart_cmd_freqs
typeset -A _smart_cmd_recency
_smart_current_index=0

# --- 1. Frequency & Recency Tracking ---

# Load existing frequencies on startup
if [[ -f "$SMART_HISTORY_FILE" ]]; then
  # Simple parsing: specific implementation may vary, strictly dependent on file format.
  # Here we assume simpler line-by-line log for robustness, calculated on load.
  while read -r line; do
    # Use 'let' for arithmetic to handle special chars in keys safely IF keys were variables,
    # but for associative array keys in Zsh, direct assignment is often cleaner.
    # However, let's stick to the previous pattern but add recency.
    (( _smart_cmd_freqs[\$line]++ ))
    _smart_cmd_recency[$line]=$((++_smart_current_index))
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
    _smart_cmd_recency[$cmd]=$((++_smart_current_index))
    
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
  setopt localoptions extendedglob
  # If we are continuing a search...
  if [[ $LASTWIDGET == "smart-history-up" ]]; then
    (( _smart_history_index++ ))
    if (( _smart_history_index > $#_smart_history_matches )); then
       _smart_history_index=1 # Cycle back to top
    fi
    BUFFER="${_smart_history_matches[$_smart_history_index]}"
    CURSOR=$#BUFFER
    return
  fi

  # Start a new search
  _smart_history_original_buffer="$BUFFER"
  _smart_history_index=1 # 1-based index for zsh arrays
  _smart_history_matches=()

  # 1. Identify candidates matching the current buffer (Fuzzy)
  local search_term="$BUFFER"
  local -A candidates
  
  # Construct Fuzzy Pattern: "a b" -> "*a*b*"
  # We use Zsh's parameter expansion to replace every character? No, usually just spaces or empty -> *
  # Simple fuzzy: Insert * between characters? Or just surround with *?
  # User asked for "Fuzzy Matching".
  # Let's do: *c*h*a*r*s* (interlace with *)
  # But be careful with performance on massive history.
  # Let's try "Smart Case" + "Boundaries".
  # Construct Fuzzy Pattern: "a b" -> "*a*b*"
  # True fuzzy matching needs wildcards between EVERY character
  # s:: splits into chars, j:*: joins with *
  local fuzzy_pattern="*${(j:*:)${(s::)search_term}}*"

  local -a scored_cmds
  
  # Iterate over all known commands
  for cmd count in "${(@kv)_smart_cmd_freqs}"; do
    # Check match (case-insensitive usually preferred for fuzzy, let's use (#i) flag)
    # properly quote the variable for pattern matching context
    if [[ "$cmd" == (#i)$~fuzzy_pattern ]]; then
      local recency="${_smart_cmd_recency[$cmd]}"
      # Format for sorting: "weighted_score:cmd"
      # Recency is weighted 10x more than frequency
      # We pad numbers with leading zeros to ensure correct string-based sorting
      # 9 digits should be enough for both frequency and index.
      local weighted_score=$(( (recency * 10) + count ))
      local sort_key
      printf -v sort_key "%09d:%s" "$weighted_score" "$cmd"
      scored_cmds+=("$sort_key")
    fi
  done

  if [[ ${#scored_cmds} -eq 0 ]]; then
     zle up-line-or-history
     return
  fi

  # 2. Sort by Key (Weighted Score DESC)
  # (On) = Descending, Numeric (though padding makes string sort safe too)
  # We use standard string sort (O) because we padded the numbers.
  local -a sorted_scored
  sorted_scored=("${(@O)scored_cmds}")

  # 3. Strip the sort keys to get clean commands
  # Remove the "WEIGHTED_SCORE:" prefix (one group of digits and colon)
  _smart_history_matches=("${sorted_scored[@]#[0-9]*:}")

  # 4. Apply first match
  if [[ ${#_smart_history_matches} -ge 1 ]]; then
    BUFFER="${_smart_history_matches[1]}"
    CURSOR=$#BUFFER
  else
    zle up-line-or-history
  fi
}

_smart_history_down() {
  setopt localoptions extendedglob
  # If we are continuing a search (either from up or down)...
  if [[ $LASTWIDGET == "smart-history-up" || $LASTWIDGET == "smart-history-down" ]]; then
    (( _smart_history_index-- ))
    if (( _smart_history_index < 1 )); then
       _smart_history_index=$#_smart_history_matches # Cycle to end
    fi
    BUFFER="${_smart_history_matches[$_smart_history_index]}"
    CURSOR=$#BUFFER
    return
  fi

  # Not in a search, use standard down navigation
  zle down-line-or-history
}

# Define the widgets
zle -N smart-history-up _smart_history_up
zle -N smart-history-down _smart_history_down

# --- 3. Key Bindings ---
bindkey '^[[A' smart-history-up
bindkey '^P' smart-history-up
bindkey '^[[B' smart-history-down
bindkey '^N' smart-history-down

