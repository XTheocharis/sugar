#!/bin/bash
# Sugar Development Environment Setup Hook
# This script sets up the development environment for Claude Code sessions

set -e

cd "$(dirname "$0")/../.."

LOG_FILE="/tmp/sugar-setup-$$.log"

log() {
    echo "$1" >> "$LOG_FILE"
}

log "=== Environment at START ==="
env >> "$LOG_FILE" 2>&1
log "=== End of START environment ==="
log ""
log "Setting up Sugar development environment..."

# Check if .venv exists with correct Python version, create if not
REQUIRED_PYTHON="3.13"
RECREATE_VENV=false

if [ ! -d ".venv" ]; then
    RECREATE_VENV=true
elif ! .venv/bin/python --version 2>/dev/null | grep -q "Python ${REQUIRED_PYTHON}"; then
    log "Upgrading venv to Python ${REQUIRED_PYTHON}..."
    rm -rf .venv
    RECREATE_VENV=true
fi

if [ "$RECREATE_VENV" = true ]; then
    log "Creating virtual environment with Python ${REQUIRED_PYTHON}..."
    uv venv --python "${REQUIRED_PYTHON}" --seed .venv >> "$LOG_FILE" 2>&1
    # Always install deps after creating fresh venv
    log "Installing dependencies..."
    uv pip install -e ".[dev,test]" >> "$LOG_FILE" 2>&1
elif ! .venv/bin/python -c "import sugar" 2>/dev/null; then
    # Existing venv but deps missing
    log "Installing dependencies..."
    uv pip install -e ".[dev,test]" >> "$LOG_FILE" 2>&1
fi

# Verify installation
VERSION=$(.venv/bin/python -c "from sugar.__version__ import __version__; print(__version__)")
log "Sugar v${VERSION} ready"

# Initialize Sugar configuration if not already done
if [ ! -d ".sugar" ]; then
    log "Initializing Sugar configuration..."
    .venv/bin/sugar init >> "$LOG_FILE" 2>&1
fi

log "Development environment ready!"
log ""
log "=== Environment at END ==="
env >> "$LOG_FILE" 2>&1
log "=== End of END environment ==="
echo "Sugar v${VERSION} ready (log: $LOG_FILE)"
