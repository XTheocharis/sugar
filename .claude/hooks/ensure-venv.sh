#!/bin/bash
# Bash PreToolUse Hook - Ensures commands run within the virtual environment
# Outputs JSON with decision/updatedInput format per Claude Code hooks spec

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_ACTIVATE="$PROJECT_ROOT/.venv/bin/activate"

# Read the input JSON from stdin
INPUT=$(cat)

# Extract the command from the JSON
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

# If no command or venv doesn't exist, approve without modification
if [ -z "$COMMAND" ] || [ ! -f "$VENV_ACTIVATE" ]; then
    exit 0
fi

# Skip if command already sources venv or uses venv binaries directly
if [[ "$COMMAND" == *".venv/bin/"* ]] || [[ "$COMMAND" == *"source .venv"* ]] || [[ "$COMMAND" == *". .venv"* ]]; then
    exit 0
fi

# Skip for commands that don't need venv (basic system commands)
if [[ "$COMMAND" =~ ^(cd|ls|pwd|echo|cat|mkdir|rm|cp|mv|git|which|type|export|source|\.)[[:space:]] ]] || \
   [[ "$COMMAND" =~ ^(cd|ls|pwd|echo|cat|mkdir|rm|cp|mv|git|which|type)$ ]]; then
    exit 0
fi

# Prepend venv activation to the command
MODIFIED_COMMAND="source $VENV_ACTIVATE && $COMMAND"

# Output in Claude Code hooks format: decision + updatedInput
jq -n \
    --arg cmd "$MODIFIED_COMMAND" \
    '{
        "decision": "approve",
        "reason": "Activating venv for command execution",
        "updatedInput": {
            "command": $cmd
        }
    }'
