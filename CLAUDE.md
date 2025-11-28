# Sugar - AI Assistant Instructions

This file provides instructions and context for AI coding assistants working with the Sugar codebase.

## Project Overview

**Sugar** is an autonomous development system that integrates with Claude Code CLI to provide continuous, background task execution. It discovers work from GitHub issues, error logs, and code analysis, then executes development tasks using Claude agents.

- **Package Name**: `sugarai`
- **Version**: 2.1.0
- **Python**: 3.13 (supports 3.11, 3.12, 3.13)
- **Entry Point**: `sugar.main:cli`
- **Repository**: https://github.com/cdnsteve/sugar

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
- Verifies installation by importing sugar module

**Bash PreToolUse Hook** (`.claude/hooks/ensure-venv.sh`):
- Automatically activates the venv for all bash commands
- Reads input JSON and modifies commands to prepend venv activation
- Skips activation for:
  - Commands already using venv binaries (`.venv/bin/...`)
  - System commands (cd, ls, pwd, echo, cat, mkdir, rm, cp, mv, git, which, type, export, source)
- Outputs JSON with `decision`, `reason`, and `updatedInput` per Claude Code hooks spec

Both hooks are configured in `.claude/settings.json`.

### Run Commands
```bash
# With activated venv
source .venv/bin/activate
pytest tests/
ruff check .
ruff format .

# Or use uv run (no activation needed)
uv run pytest tests/
uv run ruff check .
```

## Project Structure

```
sugar/
├── sugar/                    # Main package
│   ├── __init__.py
│   ├── __version__.py        # Version management (reads from pyproject.toml via tomllib)
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
│   ├── quality_gates/        # Quality verification system (70% complete)
│   │   ├── coordinator.py    # QualityGatesCoordinator
│   │   ├── test_validator.py # Test execution validation
│   │   ├── success_criteria.py # Success criteria verification
│   │   ├── truth_enforcer.py # Proof-based claim verification
│   │   ├── functional_verifier.py # HTTP/port verification
│   │   ├── preflight_checks.py # Pre-task environment checks
│   │   ├── failure_handler.py # Retry and escalation logic
│   │   ├── diff_validator.py # Git change validation
│   │   └── evidence.py       # Evidence collection
│   ├── storage/              # Database and persistence
│   │   ├── work_queue.py     # SQLite-based work queue
│   │   └── task_type_manager.py # Custom task types
│   ├── utils/
│   │   └── git_operations.py # Git helper functions
│   └── workflow/
│       └── orchestrator.py   # Workflow orchestration
├── tests/                    # Test suite
│   ├── conftest.py           # Pytest fixtures
│   ├── test_cli.py           # CLI command tests
│   ├── test_core_loop.py     # Core loop tests
│   ├── test_storage.py       # Database tests
│   ├── test_quality_gates.py # Quality gates tests
│   ├── test_hold_functionality.py # Hold/unhold tests
│   ├── test_task_types.py    # Task type management tests
│   └── plugin/               # Plugin integration tests
│       ├── test_integration.py
│       └── test_structure.py
├── docs/
│   ├── user/                 # User documentation
│   │   ├── quick-start.md
│   │   ├── cli-reference.md
│   │   ├── github-integration.md
│   │   ├── configuration-best-practices.md
│   │   └── troubleshooting.md
│   └── dev/                  # Developer documentation
│       ├── contributing.md
│       ├── local-development.md
│       └── technical-implementation-plan.md
├── config/
│   └── sugar.yaml            # Default configuration template
├── .claude/                  # Claude Code configuration
│   ├── hooks/
│   │   ├── setup-dev-env.sh  # SessionStart hook
│   │   └── ensure-venv.sh    # Bash PreToolUse hook
│   └── settings.json         # Hook configuration
├── .claude-plugin/           # Claude Code plugin files
│   ├── plugin.json           # Plugin manifest
│   ├── commands/             # Slash commands (sugar-task, sugar-status, etc.)
│   ├── agents/               # Agent definitions (task-planner, quality-guardian, etc.)
│   ├── hooks/                # Hook configurations
│   └── mcp-server/           # MCP server implementation (Node.js)
├── pyproject.toml            # Project configuration (build, ruff, mypy, pytest)
├── .pre-commit-config.yaml   # Pre-commit hooks
├── CLAUDE.md                 # This file
├── AGENTS.md                 # Additional agent context
└── README.md                 # Project overview
```

## Key Modules

### Core (`sugar/core/loop.py`)
- `SugarLoop`: Main orchestrator that runs the continuous development loop
- Manages discovery modules, work queue, and Claude executor
- Handles graceful shutdown via signal handlers

### CLI (`sugar/main.py`)
- Click-based command interface with extensive functionality
- Main commands: `init`, `add`, `run`, `status`, `list`, `hold`, `unhold`, `remove`
- Task type management: `task-type list|add|edit|remove|show|export|import`
- Configuration via `.sugar/config.yaml`

### Quality Gates (`sugar/quality_gates/`)
- **Phase 1** (Complete): Mandatory test execution, success criteria verification, truth enforcement
- **Phase 2** (Complete): Functional verification layer (HTTP, ports), pre-flight checks
- **Phase 3** (Complete): Failure handling with retries, diff validation
- Enforces mandatory verification before task completion
- Prevents false success claims without proof
- Evidence stored in `.sugar/test_evidence/` and `.sugar/evidence/`

### Storage (`sugar/storage/`)
- SQLite database with SQLAlchemy (async via aiosqlite)
- `WorkQueue`: Priority-based task queue with status tracking
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
The project uses pre-commit with these hooks (see `.pre-commit-config.yaml`):
- `pre-commit-hooks` v5.0.0 - trailing-whitespace, end-of-file-fixer, check-yaml, check-toml, etc.
- `ruff-pre-commit` v0.8.6 - Linting and formatting
- `mirrors-mypy` v1.14.1 - Type checking with types-PyYAML, types-requests
- `bandit` v1.8.3 - Security scanning
- Local `pytest` hook - Runs tests on commit

Install hooks: `pre-commit install`

### Type Hints
- All functions should have type hints
- Strict mypy configuration in `pyproject.toml` (strict = true)
- Import types from `typing` module
- Type stubs installed: types-PyYAML, types-requests, types-setuptools

### Ruff Configuration
- Line length: 88
- Target version: Python 3.13
- Select rules: E, W, F, I (isort), B (bugbear), C4 (comprehensions), UP (pyupgrade), D (pydocstyle)
- Many docstring rules ignored for flexibility (D100, D101, D104, D105, D107, etc.)
- Per-file ignores: tests ignore docstring rules and unused vars

## Testing

### Running Tests
```bash
# Full test suite with coverage (default from pyproject.toml)
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
- Test files: `test_*.py` or `*_test.py` pattern
- Use fixtures from `tests/conftest.py`
- Mock external dependencies (Claude CLI, GitHub API)
- Use `pytest-asyncio` for async tests (mode: auto)
- Use `temp_dir` fixture for file system tests

### Key Fixtures (from conftest.py)
- `temp_dir`: Temporary directory (auto-cleanup)
- `mock_project_dir`: Project with src/, tests/, logs/errors/ structure
- `sugar_config`: Sample configuration dict with all sections
- `sugar_config_file`: Config file written to mock project
- `cli_runner`: Click CLI test runner
- `mock_claude_cli`: Patched subprocess.run for Claude CLI
- `sample_error_log`: JSON error log file in mock project
- `sample_tasks`: List of sample task dicts
- `event_loop`: Session-scoped asyncio event loop
- `mock_work_queue`: Async WorkQueue with temp database

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

### Version Reading
```python
# Version is read from pyproject.toml via tomllib
from sugar.__version__ import __version__
```

## CLI Commands Reference

```bash
# Initialize Sugar in a project
sugar init [PROJECT_DIR]

# Add tasks
sugar add "Task title" --type bug_fix --priority 5
sugar add "Complex task" --json --description '{"priority": 5, ...}'

# Task management
sugar list                    # List all tasks
sugar list --status pending   # Filter by status
sugar list --type feature     # Filter by type
sugar list --format json      # JSON output
sugar status                  # Show queue status
sugar hold <task_id> --reason "Waiting for API"  # Put task on hold
sugar unhold <task_id>        # Resume task
sugar remove <task_id>        # Remove task

# Run the loop
sugar run                     # Continuous mode
sugar run --once              # Single cycle
sugar run --dry-run           # Test mode
sugar run --validate          # Validation mode

# Task types
sugar task-type list          # List custom types
sugar task-type list --format json
sugar task-type add <id> --name "Name" --emoji "icon"
sugar task-type edit <id> --name "New Name"
sugar task-type remove <id> [--force]
sugar task-type show <id>
sugar task-type export <file>
sugar task-type import <file>
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
    context_file: ".sugar/context.json"

  discovery:
    github:
      enabled: true
      repo: "user/repo"
    error_logs:
      enabled: true
      paths: ["logs/errors/"]
      patterns: ["*.json", "*.log"]
      max_age_hours: 24
    code_quality:
      enabled: true
      root_path: "."
      file_extensions: [".py"]
      excluded_dirs: ["__pycache__", ".git"]
    test_coverage:
      enabled: true
      source_dirs: ["src"]
      test_dirs: ["tests"]

  storage:
    database: "sugar.db"
    backup_interval: 3600

  safety:
    max_retries: 3
    excluded_paths: ["/System", "/usr/bin", ".sugar"]

  logging:
    level: "INFO"
    file: ".sugar/sugar.log"

  quality_gates:
    mandatory_testing:
      enabled: true
      block_commits: true
      test_commands:
        default: "pytest"
    truth_enforcement:
      enabled: true
      mode: "strict"
      block_unproven_success: true
```

## Dependencies

### Core Dependencies
- `click>=8.1.8` - CLI framework
- `pyyaml>=6.0.2` - YAML configuration
- `sqlalchemy>=2.0.36` - Database ORM
- `aiosqlite>=0.20.0` - Async SQLite
- `python-dotenv>=1.0.1` - Environment variables
- `asyncio-throttle>=1.0.2` - Rate limiting
- `setuptools>=75.0.0` - Build tools

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
4. Type checking passes (`mypy`) - some warnings expected
5. Security scan clean (`bandit -c pyproject.toml`)

## Important Notes

### Development Practices
- Always run `ruff format` and `ruff check --fix` before committing
- Sugar uses async/await extensively - use `asyncio.run()` for sync contexts
- Configuration validation should provide meaningful error messages
- The Claude CLI is mocked in tests via subprocess.run patching
- Use `click.echo()` for user output, never `print()`
- Path operations should use `pathlib.Path`

### Quality Gates Behavior
- Quality Gates may cause previously "successful" tasks to fail - this is intentional
- Tasks cannot claim success without proof (test results, verification)
- Evidence is stored in `.sugar/test_evidence/` and `.sugar/evidence/`
- Breaking changes: Tasks that previously passed may now fail if they lack verification

### Testing Notes
- Tests use relaxed failure handling in CI to unblock pipeline
- Integration tests mock Claude CLI with patch on subprocess.run
- Use temporary directories for file system tests
- Focus on core functionality tests first

### Bandit Configuration
- Skips: B101 (assert), B601 (shell injection - needed for subprocess)
- Run with config: `bandit -c pyproject.toml -r sugar/`

## Claude Code Plugin

Sugar includes a Claude Code plugin for native integration:

**Slash Commands** (`.claude-plugin/commands/`):
- `/sugar-task` - Create tasks with rich context
- `/sugar-status` - Check queue and progress
- `/sugar-run` - Start autonomous mode
- `/sugar-review` - Review pending tasks
- `/sugar-analyze` - Analyze code for potential work

**Agents** (`.claude-plugin/agents/`):
- `task-planner.md` - Task planning agent
- `sugar-orchestrator.md` - Orchestration agent
- `quality-guardian.md` - Quality verification agent

**MCP Server** (`.claude-plugin/mcp-server/`):
- Node.js implementation (`sugar-mcp.js`)
- Enables real-time task queue access from Claude

## See Also

- [README.md](README.md) - Project overview and quick start
- [AGENTS.md](AGENTS.md) - Additional agent context
- [docs/dev/contributing.md](docs/dev/contributing.md) - Contribution guide
- [docs/user/cli-reference.md](docs/user/cli-reference.md) - Full CLI documentation
- [sugar/quality_gates/README.md](sugar/quality_gates/README.md) - Quality gates documentation
