#!/usr/bin/env zsh

HIST_FILE="${SMART_HISTORY_FILE:-$HOME/.zsh_cmd_frequency_log}"
TEMP_FILE="${HIST_FILE}.tmp"

if [[ ! -f "$HIST_FILE" ]]; then
  echo "No history file found at $HIST_FILE"
  exit 1
fi

echo "Migrating $HIST_FILE to timestamped single-line format..."

python3 - "$HIST_FILE" "$TEMP_FILE" <<'EOF'
import sys
import time
import re

input_path = sys.argv[1]
output_path = sys.argv[2]
placeholder = "__SMART_HIST_NL__"
now = int(time.time())

def format_entry(cmd_lines):
    full_str = placeholder.join(cmd_lines)
    # Check if already timestamped: <digits_10+>|<cmd>
    if re.match(r'^\d{10,}\|', full_str):
        return full_str + '\n'
    return f"{now}|{full_str}\n"

with open(input_path, 'r', errors='replace') as f_in, open(output_path, 'w') as f_out:
    current_cmd = []
    
    for line in f_in:
        stripped = line.rstrip('\n')
        
        if not current_cmd:
            current_cmd.append(stripped)
        else:
            prev_line = current_cmd[-1]
            if prev_line.strip().endswith('\\') or line.startswith('  '):
                current_cmd.append(stripped)
            else:
                f_out.write(format_entry(current_cmd))
                current_cmd = [stripped]
                
    if current_cmd:
        f_out.write(format_entry(current_cmd))
EOF

if [[ -f "$TEMP_FILE" ]]; then
  mv "$TEMP_FILE" "$HIST_FILE"
  echo "Migration complete."
else
  echo "Migration failed."
  exit 1
fi

