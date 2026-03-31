#!/usr/bin/env zsh

HIST_FILE="${SMART_HISTORY_FILE:-$HOME/.zsh_cmd_frequency_log}"
TEMP_FILE="${HIST_FILE}.tmp"

if [[ ! -f "$HIST_FILE" ]]; then
  echo "No history file found at $HIST_FILE"
  exit 1
fi

echo "Migrating $HIST_FILE to new single-line format..."

# We use quoted EOF to prevent Zsh from interpreting the Python content.
# We pass the paths as arguments to avoid needing shell expansion inside.
python3 - "$HIST_FILE" "$TEMP_FILE" <<'EOF'
import sys

input_path = sys.argv[1]
output_path = sys.argv[2]
placeholder = "__SMART_HIST_NL__"

with open(input_path, 'r', errors='replace') as f_in, open(output_path, 'w') as f_out:
    current_cmd = []
    
    for line in f_in:
        stripped = line.rstrip('\n')
        
        if not current_cmd:
            current_cmd.append(stripped)
        else:
            # If the previous line ended with \, it's definitely continuation.
            # Also, if the current line starts with significant whitespace (common in multi-line history).
            prev_line = current_cmd[-1]
            if prev_line.strip().endswith('\\') or line.startswith('  '):
                current_cmd.append(stripped)
            else:
                # Flush previous command
                f_out.write(placeholder.join(current_cmd) + '\n')
                current_cmd = [stripped]
                
    if current_cmd:
        f_out.write(placeholder.join(current_cmd) + '\n')
EOF

if [[ -f "$TEMP_FILE" ]]; then
  mv "$TEMP_FILE" "$HIST_FILE"
  echo "Migration complete."
else
  echo "Migration failed."
  exit 1
fi
