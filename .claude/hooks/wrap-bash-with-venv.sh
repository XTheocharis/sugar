#!/usr/bin/env bash
# Claude Code PreToolUse hook to execute all Bash commands through bootstrap
#
# This hook ensures ALL bash commands executed by Claude run with the proper
# bootstrap environment (venv activated, env vars set, tools in PATH).
#
# Usage: This script is called by Claude Code's PreToolUse hook system.
#        It receives the bash command via stdin as JSON.

set -euo pipefail

# Read the tool input JSON from stdin
TOOL_INPUT=$(cat)

# Extract the command from JSON
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

if [ -z "$COMMAND" ]; then
    # No command, pass through unchanged with new format
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Find bootstrap using python -c oneliner (same pattern used throughout the repo)
BOOTSTRAP_PATH=$(ls -d /home/user/* | head -1)

if [ -z "$BOOTSTRAP_PATH" ] || [ ! -f "$BOOTSTRAP_PATH" ]; then
    # Can't find bootstrap, pass through unchanged with new format
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Wrap command to execute through bootstrap with proper escaping
# Format: bootstrap -- bash -c "COMMAND"
# jq's @sh formatter properly escapes the command for shell execution
echo "$TOOL_INPUT" | jq --arg bootstrap "$BOOTSTRAP_PATH" --arg cmd "$COMMAND" \
    '{decision: "approve", updatedInput: {command: "\($bootstrap)/.venv/bin/activate && bash -c \($cmd | @sh)"}}'
