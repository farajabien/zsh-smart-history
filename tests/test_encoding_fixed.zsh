#!/usr/bin/env zsh

# Original command with backslashes and newlines
cmd=$'npx tsx src/index.ts demo \\\n  -u "https://site.com" \\\n  --yes'
print -r "Original:"
print -r -- "$cmd"
echo "----------------"

# 1. Encode: substitute literal backslashes with double backslashes
# and literal newlines with '\n'
# We use (q) for simple escaping if possible, but manual is more predictable for 'read'
encoded="${cmd//\\/\\\\}"
encoded="${encoded//$'\n'/\\n}"

print -r "Encoded (single line for file):"
print -r -- "$encoded"
echo "----------------"

# 2. Decode: reverse the substitution
# Replace '\n' with literal newline, THEN double backslash with single backslash
decoded="${encoded//\\n/$'\n'}"
decoded="${decoded//\\\\/\\}"

print -r "Decoded:"
print -r -- "$decoded"
echo "----------------"

if [[ "$cmd" == "$decoded" ]]; then
  echo "SUCCESS: Match!"
else
  echo "FAILURE: Mismatch!"
fi
