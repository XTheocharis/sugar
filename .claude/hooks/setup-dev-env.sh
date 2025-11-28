#!/bin/bash
# Sugar Development Environment Setup Hook
# This script sets up the development environment for Claude Code sessions

set -e

cd "$(dirname "$0")/../.."

echo "Setting up Sugar development environment..."

# Check if .venv exists with correct Python version, create if not
REQUIRED_PYTHON="3.13"
RECREATE_VENV=false

if [ ! -d ".venv" ]; then
    RECREATE_VENV=true
elif ! .venv/bin/python --version 2>/dev/null | grep -q "Python ${REQUIRED_PYTHON}"; then
    echo "Upgrading venv to Python ${REQUIRED_PYTHON}..."
    rm -rf .venv
    RECREATE_VENV=true
fi

if [ "$RECREATE_VENV" = true ]; then
    echo "Creating virtual environment with Python ${REQUIRED_PYTHON}..."
    uv venv --python "${REQUIRED_PYTHON}" --seed .venv
fi

# Check if dependencies are installed by verifying sugar is importable
if ! .venv/bin/python -c "import sugar" 2>/dev/null; then
    echo "Installing dependencies..."
    uv pip install -e ".[dev,test]"
fi

# Verify installation
echo "Verifying sugar installation..."
.venv/bin/python -c "from sugar.__version__ import __version__; print(f'Sugar v{__version__} ready')"

echo "Development environment ready!"
