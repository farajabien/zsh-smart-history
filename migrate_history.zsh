#!/usr/bin/env zsh

HIST_FILE="${SMART_HISTORY_FILE:-$HOME/.zsh_cmd_frequency_log}"
TEMP_FILE="${HIST_FILE}.tmp"

if [[ ! -f "$HIST_FILE" ]]; then
  echo "No history file found at $HIST_FILE"
  exit 1
fi

echo "Migrating and sanitizing $HIST_FILE..."

python3 - "$HIST_FILE" "$TEMP_FILE" <<'EOF'
import sys
import time
import re

input_path = sys.argv[1]
output_path = sys.argv[2]
placeholder = "__SMART_HIST_NL__"
now = int(time.time())

INVALID_PREFIXES = (
    '└', '├', '│', '─', 'WARN', 'Done in ', 'Progress:', 'devDependencies:',
    '++++', '...', 'const ', 'let ', 'var ', 'import ', 'async function',
    '} catch', '// ', '/*', 'Product Truth', 'UX Principles', 'Risk:',
    'Technical Scope', 'Files processed', 'No authentication', ' WARN'
)

def is_valid_cmd(cmd):
    c = cmd.strip()
    if not c:
        return False
    if len(c) == 1 and c in ('.', '+', 'y', '}'):
        return False
    for p in INVALID_PREFIXES:
        if c.startswith(p):
            return False
    return True

def process_entry(cmd_lines):
    full_str = placeholder.join(cmd_lines).strip()
    if not full_str:
        return None

    # Extract existing timestamp if present
    match = re.match(r'^(\d{10,})\|(.*)$', full_str)
    if match:
        ts = match.group(1)
        raw_cmd = match.group(2).strip()
    else:
        ts = str(now)
        raw_cmd = full_str

    # Normalize command (decode, strip, check validity)
    decoded = raw_cmd.replace(placeholder, '\n').strip()
    if not is_valid_cmd(decoded):
        return None

    encoded = decoded.replace('\n', placeholder)
    return f"{ts}|{encoded}\n"

with open(input_path, 'r', errors='replace') as f_in, open(output_path, 'w') as f_out:
    current_cmd = []
    
    for line in f_in:
        stripped = line.rstrip('\r\n')
        
        if not current_cmd:
            current_cmd.append(stripped)
        else:
            prev_line = current_cmd[-1]
            if prev_line.strip().endswith('\\') or line.startswith('  '):
                current_cmd.append(stripped)
            else:
                formatted = process_entry(current_cmd)
                if formatted:
                    f_out.write(formatted)
                current_cmd = [stripped]
                
    if current_cmd:
        formatted = process_entry(current_cmd)
        if formatted:
            f_out.write(formatted)
EOF

if [[ -f "$TEMP_FILE" ]]; then
  mv "$TEMP_FILE" "$HIST_FILE"
  echo "Migration and sanitation complete."
else
  echo "Migration failed."
  exit 1
fi


