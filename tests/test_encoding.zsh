#!/usr/bin/env zsh

cmd=$'line with \\ backslash\nand newline'
echo "Original: [$cmd]"

# Encode: escape backslashes first, then newlines
encoded="${cmd//\\/\\\\}"
encoded="${encoded//$'\n'/\\n}"
echo "Encoded:  [$encoded]"

# Decode: unescape newlines first, then backslashes
decoded="${encoded//\\n/$'\n'}"
decoded="${decoded//\\\\/\\}"
echo "Decoded:  [$decoded]"

if [[ "$cmd" == "$decoded" ]]; then
  echo "SUCCESS: Match!"
else
  echo "FAILURE: Mismatch!"
fi
