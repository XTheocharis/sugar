#!/bin/bash
# Bash PreToolUse Hook - Ensures commands run within the virtual environment
# Receives tool input as JSON on stdin, outputs modified JSON to stdout

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_ACTIVATE="$PROJECT_ROOT/.venv/bin/activate"

# Read the input JSON from stdin
INPUT=$(cat)

# Extract the command from the JSON
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

# If no command or venv doesn't exist, pass through unchanged
if [ -z "$COMMAND" ] || [ ! -f "$VENV_ACTIVATE" ]; then
    echo "$INPUT"
    exit 0
fi

# Skip if command already sources venv or uses venv binaries directly
if [[ "$COMMAND" == *".venv/bin/"* ]] || [[ "$COMMAND" == *"source .venv"* ]] || [[ "$COMMAND" == *". .venv"* ]]; then
    echo "$INPUT"
    exit 0
fi

# Skip for commands that don't need venv (basic system commands)
if [[ "$COMMAND" =~ ^(cd|ls|pwd|echo|cat|mkdir|rm|cp|mv|git|which|type|export|source|\.)[[:space:]] ]] || \
   [[ "$COMMAND" =~ ^(cd|ls|pwd|echo|cat|mkdir|rm|cp|mv|git|which|type)$ ]]; then
    echo "$INPUT"
    exit 0
fi

# Prepend venv activation to the command
MODIFIED_COMMAND="source $VENV_ACTIVATE && $COMMAND"

# Output modified JSON
echo "$INPUT" | jq --arg cmd "$MODIFIED_COMMAND" '.command = $cmd'
