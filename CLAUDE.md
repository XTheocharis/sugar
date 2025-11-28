# Sugar - AI Assistant Instructions

This file provides instructions and context for AI coding assistants working with the Sugar codebase.

## Project Overview

**Sugar** is an autonomous development system that integrates with Claude Code CLI to provide continuous, background task execution. It discovers work from GitHub issues, error logs, and code analysis, then executes development tasks using Claude agents.

- **Package Name**: `sugarai`
- **Version**: 2.1.0
- **Python**: 3.11+ (supports 3.11, 3.12, 3.13)
- **Entry Point**: `sugar.main:cli`

## Development Environment

This project supports both **uv** (recommended) and **venv** workflows.

### Using uv (Recommended - Faster)
```bash
# Install dependencies
uv pip install -e ".[dev,test,github]"

# Run commands
uv run python -m sugar ...
uv run pytest tests/
uv run black .
```

### Using venv (Traditional)
```bash
# Activate venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows

# Install dependencies
pip install -e ".[dev,test,github]"

# Run commands
python -m sugar ...
pytest tests/
black .
```

## Project Structure

```
sugar/
├── sugar/                    # Main package
│   ├── __init__.py
│   ├── __version__.py        # Version management (reads from pyproject.toml)
│   ├── main.py               # CLI entry point (Click-based)
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
│   └── plugin/               # Plugin integration tests
├── docs/
│   ├── user/                 # User documentation
│   └── dev/                  # Developer documentation
├── config/
│   └── sugar.yaml            # Default configuration template
├── .claude-plugin/           # Claude Code plugin files
│   ├── commands/             # Slash commands
│   ├── agents/               # Agent definitions
│   ├── hooks/                # Hook configurations
│   └── mcp-server/           # MCP server implementation
├── pyproject.toml            # Project configuration
├── .pre-commit-config.yaml   # Pre-commit hooks
└── CLAUDE.md                 # This file
```

## Key Modules

### Core (`sugar/core/loop.py`)
- `SugarLoop`: Main orchestrator that runs the continuous development loop
- Manages discovery modules, work queue, and Claude executor
- Handles graceful shutdown via signal handlers

### CLI (`sugar/main.py`)
- Click-based command interface
- Key commands: `init`, `add`, `run`, `status`, `list`, `task-type`
- Configuration via `.sugar/config.yaml`

### Quality Gates (`sugar/quality_gates/`)
- Enforces mandatory verification before task completion
- Prevents false success claims without proof
- Features: test execution validation, success criteria, truth enforcement, diff validation

### Storage (`sugar/storage/`)
- SQLite database with SQLAlchemy (async via aiosqlite)
- `WorkQueue`: Priority-based task queue
- `TaskTypeManager`: Custom task type definitions

## Code Quality Requirements

### Before Committing
```bash
# Format code
black sugar tests

# Sort imports
isort sugar tests

# Lint
flake8 sugar --max-line-length=88

# Run tests
pytest tests/ -v
```

### Pre-commit Hooks
The project uses pre-commit with these hooks:
- `black` (Python 3.11, line-length 88)
- `flake8` with `flake8-docstrings`
- `isort` (black profile)
- `mypy` with type stubs
- `bandit` security scanning
- `pytest` on commit

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
- `temp_dir`: Temporary directory
- `mock_project_dir`: Project with typical structure
- `sugar_config`: Sample configuration dict
- `sugar_config_file`: Config file in mock project
- `cli_runner`: Click CLI test runner
- `mock_claude_cli`: Mocked subprocess.run for Claude
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

```bash
# Initialize Sugar in a project
sugar init

# Add tasks
sugar add "Task title" --type bug_fix --priority 5
sugar add "Complex task" --json --description '{"priority": 5, ...}'

# Task management
sugar list                    # List all tasks
sugar list --status pending   # Filter by status
sugar status                  # Show queue status
sugar hold <task_id>          # Put task on hold
sugar unhold <task_id>        # Resume task
sugar remove <task_id>        # Remove task

# Run the loop
sugar run                     # Continuous mode
sugar run --once              # Single cycle

# Task types
sugar task-type list          # List custom types
sugar task-type add <id>      # Add custom type
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

  discovery:
    github:
      enabled: true
      repo: "user/repo"
    error_logs:
      enabled: true
      paths: ["logs/errors/"]
    code_quality:
      enabled: true
    test_coverage:
      enabled: true

  storage:
    database: "sugar.db"
```

## Dependencies

### Core Dependencies
- `click>=8.1.0` - CLI framework
- `pyyaml>=6.0` - YAML configuration
- `sqlalchemy>=2.0.0` - Database ORM
- `aiosqlite>=0.19.0` - Async SQLite

### Optional Dependencies
- `[github]`: `PyGithub>=1.59.0`
- `[dev]`: black, flake8, isort, mypy, bandit, pre-commit
- `[test]`: pytest, pytest-asyncio, pytest-cov

## PR and Commit Guidelines

### Commit Message Format (Conventional Commits)
```
type(scope): description

Detailed explanation if needed.

Closes #123
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### PR Requirements
1. Tests pass (`pytest`)
2. Code formatted (`black`, `isort`)
3. Linting passes (`flake8`)
4. Type checking passes (`mypy`)
5. Security scan clean (`bandit`)

## Important Notes

- Always run Black formatting before committing
- Sugar uses async/await extensively - use `asyncio.run()` for sync contexts
- Configuration validation should provide meaningful error messages
- The Claude CLI is mocked in tests at `/tmp/mock-claude/claude`
- Quality Gates may cause previously "successful" tasks to fail - this is intentional
- Evidence is stored in `.sugar/test_evidence/` and `.sugar/evidence/`

## See Also

- [README.md](README.md) - Project overview and quick start
- [AGENTS.md](AGENTS.md) - Additional agent context
- [docs/dev/contributing.md](docs/dev/contributing.md) - Contribution guide
- [sugar/quality_gates/README.md](sugar/quality_gates/README.md) - Quality gates documentation
