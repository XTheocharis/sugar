#!/usr/bin/env bash
# Claude Code PreToolUse hook to execute Bash commands with venv activated
#
# This hook ensures Python-related bash commands run with the virtual
# environment activated. System commands pass through unchanged.
#
# Usage: Called by Claude Code's PreToolUse hook system.
#        Receives the bash command via stdin as JSON.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Read the tool input JSON from stdin
TOOL_INPUT=$(cat)

# Extract the command from JSON
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

if [ -z "$COMMAND" ]; then
    # No command, pass through unchanged
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

VENV_ACTIVATE="${PROJECT_ROOT}/.venv/bin/activate"

# Check if venv exists
if [ ! -f "$VENV_ACTIVATE" ]; then
    # No venv, pass through unchanged
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Skip if command already activates venv
if [[ "$COMMAND" == *"source"*"activate"* ]] || [[ "$COMMAND" == *". "*"activate"* ]]; then
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Skip if command already uses venv binaries directly
if [[ "$COMMAND" == *".venv/bin/"* ]]; then
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Skip for commands that don't need venv (basic system commands)
# Match: command at start, optionally followed by space and args
if echo "$COMMAND" | grep -qE '^(cd|ls|pwd|echo|cat|head|tail|mkdir|rm|cp|mv|git|which|type|export|source|sleep|wait|kill|ps|top|df|du|find|grep|sed|awk|sort|uniq|wc|tr|cut|paste|diff|touch|chmod|chown|ln|tar|gzip|gunzip|zip|unzip|curl|wget|ssh|scp|rsync|docker|kubectl|helm|make|cmake|npm|yarn|pnpm|bun|node|deno|go|cargo|rustc|ruby|gem|bundle|java|javac|mvn|gradle|dotnet|gh|jq|yq|fd|rg|bat|exa|fzf|tmux|screen|vim|nvim|nano|less|more|man|env|printenv|set|unset|alias|history|date|cal|uptime|whoami|id|groups|uname|hostname|ifconfig|ip|netstat|ss|ping|traceroute|dig|nslookup|host)($|[[:space:]])'; then
    echo "{\"decision\":\"approve\",\"updatedInput\":$TOOL_INPUT}"
    exit 0
fi

# Wrap command to execute with venv activated
# Use jq's @sh to properly escape the command for shell execution
echo "$TOOL_INPUT" | jq --arg activate "$VENV_ACTIVATE" --arg cmd "$COMMAND" \
    '{decision: "approve", updatedInput: {command: "source \($activate) && \($cmd)"}}'
