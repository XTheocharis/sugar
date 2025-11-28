# Sugar - AI Assistant Instructions

This file provides instructions and context for AI coding assistants working with the Sugar codebase.

## Project Overview

**Sugar** is an autonomous development system that integrates with Claude Code CLI to provide continuous, background task execution. It discovers work from GitHub issues, error logs, and code analysis, then executes development tasks using Claude agents.

- **Package Name**: `sugarai`
- **Version**: 2.1.0
- **Python**: 3.13 (supports 3.11, 3.12, 3.13)
- **Entry Point**: `sugar.main:cli`

## Development Environment

This project uses **uv** for fast dependency management.

### Quick Setup
```bash
# Create venv with Python 3.13 and seed packages
uv venv --python 3.13 --seed .venv

# Install dependencies
uv pip install -e ".[dev,test]"

# Activate and verify
source .venv/bin/activate
sugar --version
```

### Claude Code Hooks
Two hooks automatically manage the development environment:

**SessionStart Hook** (`.claude/hooks/setup-dev-env.sh`):
- Creates venv with Python 3.13 if missing or outdated
- Installs project dependencies via `uv pip install -e ".[dev,test]"`
- Runs `sugar init` to initialize Sugar configuration

**Bash PreToolUse Hook** (`.claude/hooks/ensure-venv.sh`):
- Automatically activates the venv for all bash commands
- Skips activation for system commands (git, ls, cd, etc.)
- Skips if command already uses venv binaries directly
- Outputs JSON with `decision`/`updatedInput` format per Claude Code hooks spec

Both hooks are configured in `.claude/settings.json`.

### Run Commands
```bash
# With activated venv
source .venv/bin/activate
pytest tests/
ruff check .
ruff format .

# Or use uv run
uv run pytest tests/
uv run ruff check .
```

## Project Structure

```
sugar/
├── sugar/                    # Main package
│   ├── __init__.py
│   ├── __version__.py        # Version management (reads from pyproject.toml)
│   ├── main.py               # CLI entry point (Click-based, ~2800 lines)
│   ├── core/
│   │   └── loop.py           # SugarLoop - main orchestrator
│   ├── discovery/            # Work discovery modules
│   │   ├── error_monitor.py  # Error log monitoring
│   │   ├── github_watcher.py # GitHub issue discovery
│   │   ├── code_quality.py   # Code quality scanning
│   │   └── test_coverage.py  # Test coverage analysis
│   ├── executor/             # Claude Code CLI execution
│   │   ├── claude_wrapper.py # Claude CLI wrapper
│   │   └── structured_request.py # Structured JSON requests
│   ├── learning/             # Adaptive learning system
│   │   ├── feedback_processor.py
│   │   └── adaptive_scheduler.py
│   ├── quality_gates/        # Quality verification system
│   │   ├── coordinator.py    # QualityGatesCoordinator
│   │   ├── test_validator.py # Test execution validation
│   │   ├── success_criteria.py # Success criteria verification
│   │   ├── truth_enforcer.py # Proof-based claim verification
│   │   ├── functional_verifier.py # HTTP/port verification
│   │   ├── preflight_checks.py # Pre-task environment checks
│   │   ├── failure_handler.py # Retry and escalation logic
│   │   ├── diff_validator.py # Git change validation
│   │   ├── evidence.py       # Evidence collection
│   │   └── README.md         # Quality gates documentation
│   ├── storage/              # Database and persistence
│   │   ├── work_queue.py     # SQLite-based work queue
│   │   └── task_type_manager.py # Custom task types
│   ├── utils/
│   │   └── git_operations.py # Git helper functions
│   └── workflow/
│       └── orchestrator.py   # Workflow orchestration
├── tests/                    # Test suite
│   ├── __init__.py
│   ├── conftest.py           # Pytest fixtures
│   ├── test_cli.py           # CLI command tests
│   ├── test_core_loop.py     # Core loop tests
│   ├── test_storage.py       # Database tests
│   ├── test_quality_gates.py # Quality gates tests
│   ├── test_hold_functionality.py # Hold/release tests
│   ├── test_task_types.py    # Task type management tests
│   └── plugin/               # Plugin integration tests
│       ├── __init__.py
│       ├── test_structure.py # Plugin structure tests
│       └── test_integration.py # Plugin integration tests
├── docs/
│   ├── README.md
│   ├── user/                 # User documentation
│   │   ├── quick-start.md
│   │   ├── cli-reference.md
│   │   ├── github-integration.md
│   │   ├── configuration-best-practices.md
│   │   ├── troubleshooting.md
│   │   └── ...
│   └── dev/                  # Developer documentation
│       ├── contributing.md
│       ├── local-development.md
│       └── ...
├── config/
│   └── sugar.yaml            # Default configuration template
├── .claude/                  # Claude Code configuration
│   ├── hooks/
│   │   ├── setup-dev-env.sh  # SessionStart hook
│   │   └── ensure-venv.sh    # Bash PreToolUse hook
│   └── settings.json         # Hook configuration
├── .claude-plugin/           # Claude Code plugin files
│   ├── plugin.json           # Plugin manifest
│   ├── .mcp.json             # MCP server configuration
│   ├── README.md             # Plugin documentation
│   ├── commands/             # Slash commands
│   │   ├── sugar-status.md
│   │   ├── sugar-task.md
│   │   ├── sugar-analyze.md
│   │   ├── sugar-review.md
│   │   └── sugar-run.md
│   ├── agents/               # Agent definitions
│   │   ├── sugar-orchestrator.md
│   │   ├── task-planner.md
│   │   └── quality-guardian.md
│   ├── hooks/
│   │   └── hooks.json
│   └── mcp-server/           # MCP server implementation
│       ├── sugar-mcp.js
│       └── package.json
├── pyproject.toml            # Project configuration
├── .pre-commit-config.yaml   # Pre-commit hooks
├── AGENTS.md                 # Additional agent context
└── CLAUDE.md                 # This file
```

## Key Modules

### Core (`sugar/core/loop.py`)
- `SugarLoop`: Main orchestrator that runs the continuous development loop
- Manages discovery modules, work queue, and Claude executor
- Handles graceful shutdown via signal handlers

### CLI (`sugar/main.py`)
- Click-based command interface with ~20 commands
- Main commands: `init`, `add`, `run`, `status`, `list`, `view`
- Task management: `hold`, `release`, `update`, `priority`, `remove`
- Utilities: `stop`, `debug`, `logs`, `dedupe`, `cleanup`, `help`
- Subcommand group: `task-type` with `list`, `add`, `edit`, `remove`, `show`, `export`, `import`
- Configuration via `.sugar/config.yaml`

### Quality Gates (`sugar/quality_gates/`)
- Enforces mandatory verification before task completion
- Prevents false success claims without proof
- Features: test execution validation, success criteria, truth enforcement, diff validation

### Storage (`sugar/storage/`)
- SQLite database with SQLAlchemy (async via aiosqlite)
- `WorkQueue`: Priority-based task queue with hold/release support
- `TaskTypeManager`: Custom task type definitions with CRUD operations

## Code Quality Requirements

### Before Committing
```bash
# Format and lint with ruff (single tool for both)
ruff format sugar tests
ruff check sugar tests --fix

# Run tests
pytest tests/ -v
```

### Pre-commit Hooks
The project uses pre-commit (v5.0.0) with these hooks:
- `pre-commit-hooks` - trailing whitespace, end-of-file, YAML/TOML checks
- `ruff` (v0.8.6) - Linting with `--fix`
- `ruff-format` - Formatting
- `mypy` (v1.14.1) with type stubs (types-PyYAML, types-requests)
- `bandit` (v1.8.3) security scanning
- `pytest` on commit (local hook)

Install hooks: `pre-commit install`

### Type Hints
- All functions should have type hints
- Strict mypy configuration in `pyproject.toml`
- Import types from `typing` module

## Testing

### Running Tests
```bash
# Full test suite with coverage
pytest

# Specific test categories
pytest -m unit          # Unit tests
pytest -m integration   # Integration tests
pytest -m slow          # Slow tests

# Specific file
pytest tests/test_cli.py -v

# With coverage report
pytest --cov=sugar --cov-report=term-missing
```

### Test Conventions
- Test files: `test_*.py` pattern
- Use fixtures from `tests/conftest.py`
- Mock external dependencies (Claude CLI, GitHub API)
- Use `pytest-asyncio` for async tests (mode: auto)
- Use `temp_dir` fixture for file system tests

### Key Fixtures (from conftest.py)
- `temp_dir`: Temporary directory (auto-cleanup)
- `mock_project_dir`: Project with typical structure (src/, tests/, logs/errors/)
- `sugar_config`: Sample configuration dict
- `sugar_config_file`: Config file in mock project
- `cli_runner`: Click CLI test runner
- `mock_claude_cli`: Mocked subprocess.run for Claude
- `sample_error_log`: Sample error log file
- `sample_tasks`: Sample task data list
- `event_loop`: Session-scoped event loop for async tests
- `mock_work_queue`: Async work queue with temp database

## Common Patterns

### CLI Output
```python
# Use click.echo(), not print()
click.echo("Message to user")
click.echo(click.style("Error", fg="red"))
```

### Async Operations
```python
# Database and file I/O should be async
async def my_operation():
    await queue.add_task(task)
```

### Configuration
```python
# Load from YAML
with open(config_path, "r") as f:
    config = yaml.safe_load(f)
```

### Path Operations
```python
# Use pathlib.Path
from pathlib import Path
config_path = Path(".sugar") / "config.yaml"
```

### Error Handling
```python
# User-friendly messages with graceful degradation
try:
    result = await risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
    raise click.ClickException(f"Friendly error message")
```

## CLI Commands Reference

### Core Commands
```bash
# Initialize Sugar in a project
sugar init

# Add tasks
sugar add "Task title" --type bug_fix --priority 5
sugar add "Complex task" --json --description '{"priority": 5, ...}'

# Run the loop
sugar run                     # Continuous mode
sugar run --once              # Single cycle
sugar run --dry-run           # Simulate without changes
sugar run --validate          # Validate config first

# Stop running instance
sugar stop                    # Graceful shutdown
sugar stop --force            # Force terminate
```

### Task Management
```bash
# List and view tasks
sugar list                    # List all tasks
sugar list --status pending   # Filter by status
sugar list --format json      # JSON output
sugar view <task_id>          # View task details

# Task state management
sugar hold <task_id>          # Put task on hold
sugar hold <task_id> --reason "Waiting for clarification"
sugar release <task_id>       # Resume held task
sugar remove <task_id>        # Remove task

# Update tasks
sugar update <task_id> --title "New title"
sugar update <task_id> --priority 5 --status pending
sugar priority <task_id> --urgent    # Set priority to 5
sugar priority <task_id> --high      # Set priority to 4
sugar priority <task_id> --normal    # Set priority to 3
```

### Status and Debugging
```bash
sugar status                  # Show queue status
sugar logs                    # View recent logs
sugar logs --follow           # Tail logs
sugar logs --level ERROR      # Filter by level
sugar debug                   # Generate diagnostic report
sugar debug --format yaml     # YAML output
sugar debug --include-sensitive  # Include sensitive paths
sugar help                    # Show help
```

### Maintenance
```bash
sugar dedupe                  # Remove duplicate work items
sugar dedupe --dry-run        # Show what would be removed
sugar cleanup                 # Remove bogus items (init tests, etc.)
sugar cleanup --dry-run       # Preview cleanup
```

### Task Types
```bash
sugar task-type list          # List all task types
sugar task-type list --format json
sugar task-type add <id>      # Add custom type
sugar task-type add deployment --name "Deployment" --emoji "🚀"
sugar task-type edit <id>     # Edit existing type
sugar task-type remove <id>   # Remove custom type
sugar task-type show <id>     # Show type details
sugar task-type export        # Export types to JSON
sugar task-type import <file> # Import types from JSON
```

## Configuration

Configuration lives in `.sugar/config.yaml`. Key sections:

```yaml
sugar:
  loop_interval: 300          # Seconds between cycles
  max_concurrent_work: 3      # Parallel tasks
  dry_run: false              # Set true for testing

  claude:
    command: "claude"         # Path to Claude CLI
    timeout: 1800             # 30 min per task
    enable_agents: true       # Use specialized agents
    use_structured_requests: true
    use_continuous: true      # Enable --continue flag
    agent_selection:          # Map work types to agents
      bug_fix: "tech-lead"
      feature: "general-purpose"
      refactor: "code-reviewer"

  discovery:
    global_excluded_dirs: ["node_modules", ".git", "__pycache__", ".venv"]
    github:
      enabled: true
      repo: "user/repo"
      auth_method: "auto"     # auto | gh_cli | token
    error_logs:
      enabled: true
      paths: ["logs/errors/"]
      max_age_hours: 24
    code_quality:
      enabled: true
    test_coverage:
      enabled: true

  storage:
    database: "sugar.db"
    backup_interval: 3600

  safety:
    max_retries: 3
    excluded_paths: ["/System", "/usr/bin"]

  logging:
    level: "INFO"
    file: ".sugar/sugar.log"
```

## Dependencies

### Core Dependencies
- `click>=8.1.8` - CLI framework
- `pyyaml>=6.0.2` - YAML configuration
- `sqlalchemy>=2.0.36` - Database ORM
- `aiosqlite>=0.20.0` - Async SQLite
- `python-dotenv>=1.0.1` - Environment variables
- `asyncio-throttle>=1.0.2` - Rate limiting
- `setuptools>=75.0.0` - Package setup

### Optional Dependencies
- `[github]`: `PyGithub>=2.5.0`
- `[dev]`: ruff, mypy, bandit, pip-audit, pre-commit, type stubs
- `[test]`: pytest, pytest-asyncio, pytest-cov

## PR and Commit Guidelines

### Commit Message Format (Conventional Commits)
```
type(scope): description

Detailed explanation if needed.

Closes #123
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

### PR Requirements
1. Tests pass (`pytest`)
2. Code formatted (`ruff format`)
3. Linting passes (`ruff check`)
4. Type checking passes (`mypy`)
5. Security scan clean (`bandit`)

## Important Notes

- Always run `ruff format` and `ruff check --fix` before committing
- Sugar uses async/await extensively - use `asyncio.run()` for sync contexts
- Configuration validation should provide meaningful error messages
- The Claude CLI is mocked in tests via `mock_claude_cli` fixture
- Quality Gates may cause previously "successful" tasks to fail - this is intentional
- Evidence is stored in `.sugar/test_evidence/` and `.sugar/evidence/`
- PID file for `sugar stop` is stored in `.sugar/sugar.pid`
- Hold functionality uses `on_hold` status with optional `hold_reason` field

## Claude Code Plugin

Sugar includes a native Claude Code plugin (`.claude-plugin/`) with:
- Slash commands: `/sugar-task`, `/sugar-status`, `/sugar-run`, `/sugar-review`, `/sugar-analyze`
- Specialized agents: `sugar-orchestrator`, `task-planner`, `quality-guardian`
- MCP server integration for real-time task queue access

Install the plugin: `/plugin install sugar@cdnsteve`

## See Also

- [README.md](README.md) - Project overview and quick start
- [AGENTS.md](AGENTS.md) - Additional agent context
- [docs/dev/contributing.md](docs/dev/contributing.md) - Contribution guide
- [docs/user/cli-reference.md](docs/user/cli-reference.md) - Complete CLI reference
- [sugar/quality_gates/README.md](sugar/quality_gates/README.md) - Quality gates documentation
- [.claude-plugin/README.md](.claude-plugin/README.md) - Plugin documentation
