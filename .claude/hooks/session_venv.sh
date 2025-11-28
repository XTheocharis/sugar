#!/bin/bash
# SessionStart hook to persist venv environment using CLAUDE_ENV_FILE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect virtual environment
if [ -d "$PROJECT_ROOT/.venv" ]; then
    VENV_PATH="$PROJECT_ROOT/.venv"
elif [ -d "$PROJECT_ROOT/venv" ]; then
    VENV_PATH="$PROJECT_ROOT/venv"
elif [ -d "$PROJECT_ROOT/env" ]; then
    VENV_PATH="$PROJECT_ROOT/env"
else
    echo "No venv found" >&2
    exit 0
fi

# Capture environment before activation
ENV_BEFORE=$(export -p | sort)

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Persist environment changes to CLAUDE_ENV_FILE
if [ -n "$CLAUDE_ENV_FILE" ]; then
    ENV_AFTER=$(export -p | sort)
    # Write the difference (new/changed exports) to env file
    comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
    echo "Venv environment written to CLAUDE_ENV_FILE" >&2
else
    echo "CLAUDE_ENV_FILE not set" >&2
fi

exit 0
