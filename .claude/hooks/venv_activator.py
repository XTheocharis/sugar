#!/usr/bin/env python3
"""PreToolUse hook to auto-activate Python virtual environment for bash commands."""
import json
import sys
import os

def main():
    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)

        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})
        command = tool_input.get("command", "")

        # Only process Bash tool calls
        if tool_name != "Bash" or not command:
            sys.exit(0)

        # Check if command already activates venv
        if "source" in command and "activate" in command:
            sys.exit(0)

        # Check if command already uses venv binaries
        if ".venv/bin/" in command:
            sys.exit(0)

        # Detect virtual environment path
        project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
        venv_paths = [".venv/bin/activate", "venv/bin/activate", "env/bin/activate"]
        venv_path = None

        for path in venv_paths:
            full_path = os.path.join(project_dir, path)
            if os.path.exists(full_path):
                venv_path = full_path
                break

        if not venv_path:
            # No venv found, allow command as-is
            sys.exit(0)

        # Modify command to activate venv first
        modified_command = f"source {venv_path} && {command}"

        # Return modified input with approval using hookSpecificOutput format
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Auto-activated Python virtual environment",
                "updatedInput": {
                    "command": modified_command
                }
            }
        }

        print(json.dumps(output))
        sys.exit(0)

    except Exception as e:
        print(f"Error in venv hook: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
