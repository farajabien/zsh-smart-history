# Smart Frequency-Based History for Zsh
# https://github.com/farajabien/zsh-smart-history
#
# A Zsh plugin that overrides the Up key to search history by FREQUENCY then RECENCY.
#
# Installation: Source this file in your .zshrc
# See README.md for full instructions.

# --- Load Required Modules ---
autoload -Uz add-zsh-hook

# --- Configuration ---
SMART_HISTORY_FILE="${SMART_HISTORY_FILE:-$HOME/.zsh_cmd_frequency_log}"
typeset -A _smart_cmd_freqs
typeset -A _smart_cmd_recency
# Initialize to 0 only if unset
: ${_smart_current_index:=0}
: ${_smart_history_last_loaded_line:=0}

# --- 1. Frequency & Recency Tracking ---

_smart_history_load_new_entries() {
  if [[ -f "$SMART_HISTORY_FILE" ]]; then
    local current_lines=$(wc -l < "$SMART_HISTORY_FILE" | tr -d ' ')

    if (( current_lines > _smart_history_last_loaded_line )); then
      local lines_to_read=$(( current_lines - _smart_history_last_loaded_line ))
      
      local line
      local cur_freq
      local nl=$'\n'
      while IFS= read -r line; do
        if [[ -n "$line" ]]; then
           # Decode newlines
           line="${line//__SMART_HIST_NL__/$nl}"

           cur_freq=${_smart_cmd_freqs[$line]:-0}
           _smart_cmd_freqs[$line]=$(( cur_freq + 1 ))
           (( _smart_current_index++ ))
           _smart_cmd_recency[$line]=$_smart_current_index
        fi
      done < <(tail -n "$lines_to_read" "$SMART_HISTORY_FILE")
      
      _smart_history_last_loaded_line=$current_lines
    fi
  fi
}

# Initial Load - only if we haven't loaded anything yet
if [[ $_smart_history_last_loaded_line -eq 0 ]]; then
  _smart_history_load_new_entries
fi

_smart_history_preexec() {
  local cmd="$1"
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  cmd="${cmd%"${cmd##*[![:space:]]}"}"
  
  if [[ -n "$cmd" ]]; then
    local cur_freq=${_smart_cmd_freqs[$cmd]:-0}
    _smart_cmd_freqs[$cmd]=$(( cur_freq + 1 ))
    (( _smart_current_index++ ))
    _smart_cmd_recency[$cmd]=$_smart_current_index
    
    # Encode newlines for single-line persistence
    local encoded_cmd="${cmd//$'\n'/__SMART_HIST_NL__}"

    # Persist to log (append only for speed)
    if print -r -- "$encoded_cmd" >> "$SMART_HISTORY_FILE"; then
       # Increment last loaded line so we don't re-read our own command
       (( _smart_history_last_loaded_line++ ))

    fi
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
  if [[ $LASTWIDGET == "smart-history-up" || $LASTWIDGET == "smart-history-down" ]]; then
    # Stop if we are already at the last match
    if (( _smart_history_index >= $#_smart_history_matches )); then
       # Stay at the last match, do not cycle
       _smart_history_index=$#_smart_history_matches
       # Optionally visual bell or verify behavior
    else
       (( _smart_history_index++ ))
    fi
    
    BUFFER="${_smart_history_matches[$_smart_history_index]}"
    CURSOR=$#BUFFER
    return
  fi

  # Start a new search
  # FIRST: Check for updates from other terminals
  _smart_history_load_new_entries

  _smart_history_original_buffer="$BUFFER"
  _smart_history_index=1 # 1-based index for zsh arrays
  _smart_history_matches=()

  # 1. Identify candidates matching the current buffer (Fuzzy)
  local search_term="$BUFFER"

  # If buffer is empty, show last 5 unique commands
  if [[ -z "$search_term" ]]; then
    # Build list of commands sorted by recency
    local -a recent_cmds
    for cmd recency in "${(@kv)_smart_cmd_recency}"; do
      recent_cmds+=("$recency:$cmd")
    done

    # Sort by recency (descending) and take top 5
    recent_cmds=("${(@On)recent_cmds}")

    # Extract commands (remove recency prefix) and take first 20
    _smart_history_matches=()
    local count=0
    for entry in "${recent_cmds[@]}"; do
      if (( count >= 20 )); then
        break
      fi
      _smart_history_matches+=("${entry#*:}")
      (( count++ ))
    done

    # Show first match or fallback to standard history
    if [[ ${#_smart_history_matches} -ge 1 ]]; then
      BUFFER="${_smart_history_matches[1]}"
      CURSOR=$#BUFFER
    else
      zle up-line-or-history
    fi
    return
  fi

  local -A candidates
  local fuzzy_pattern="*${(j:*:)${(s::)search_term}}*"
  local -a scored_cmds

  # Iterate over all known commands
  for cmd count in "${(@kv)_smart_cmd_freqs}"; do
    if [[ "$cmd" == (#i)$~fuzzy_pattern ]]; then
      local recency="${_smart_cmd_recency["$cmd"]}"
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
  local -a sorted_scored
  sorted_scored=("${(@O)scored_cmds}")

  # 3. Strip the sort keys to get clean commands
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
    if (( ${#_smart_history_matches} == 0 )); then
      zle down-line-or-history
      return
    fi

    # Decrease index
    (( _smart_history_index-- ))

    # Handle boundary: if index goes to 0 (or below), show original buffer and stop
    if (( _smart_history_index <= 0 )); then
      _smart_history_index=0
      BUFFER="$_smart_history_original_buffer"
      CURSOR=$#BUFFER
      return
    fi
    
    # We do NOT wrap to the end anymore.
    
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

# --- 4. Stats Widget ---
smart_history_stats() {
  local total=0
  local -A freqs
  
  # Copy to local array and calculate total
  for cmd count in "${(@kv)_smart_cmd_freqs}"; do
    (( total += count ))
    freqs[$cmd]=$count
  done

  if (( total == 0 )); then
    echo "No history statistics available yet."
    return
  fi

  echo "Top 20 Commands (Total: $total executions)"
  echo "----------------------------------------------------------------"
  printf "%-30s | %-20s | %s\n" "Command" "Frequency" "Count"
  echo "----------------------------------------------------------------"

  # Sort by frequency desc
  local -a sort_list
  for cmd count in "${(@kv)freqs}"; do
      sort_list+=("$count:$cmd") 
  done
  
  # Sort numerically descending
  sort_list=("${(@On)sort_list}")
  
  local i=0
  for item in "${sort_list[@]}"; do
    if (( i >= 20 )); then break; fi
    
    local count="${item%%:*}"
    local cmd="${item#*:}"
    
    # Calculate percentage
    local pct=$(( (count * 100.0) / total ))
    local int_pct=${pct%.*} # Integer part
    
    # Draw bar (20 chars max)
    local bar_len=$(( (int_pct * 20) / 100 ))
    if (( bar_len == 0 && count > 0 )); then bar_len=1; fi
    local bar=""
    for ((b=0; b<bar_len; b++)); do bar+="="; done
    for ((b=bar_len; b<20; b++)); do bar+=" "; done
    
    # Print table row
    printf "%-30s | [%s] | %d (%.1f%%)\n" "${cmd:0:30}" "$bar" "$count" "$pct"
    (( i++ ))
  done
  echo "----------------------------------------------------------------"
}

