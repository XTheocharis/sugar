#!/bin/bash
# Sugar Development Environment Setup Hook
# This script sets up the development environment for Claude Code sessions

set -e

cd "$(dirname "$0")/../.."

echo "Setting up Sugar development environment..."

# Check if .venv exists, create if not
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    uv venv .venv
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
