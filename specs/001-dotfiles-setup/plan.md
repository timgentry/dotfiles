# Implementation Plan: Dotfiles Setup Command

**Branch**: `001-dotfiles-setup` | **Date**: 2026-02-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-dotfiles-setup/spec.md`

## Summary

Create a one-command dotfiles setup system that downloads the repository and configures a Mac with Homebrew packages, utility scripts in PATH, and global configurations. The setup follows the Homebrew installation pattern (curl remote script piped to bash) and uses GNU Stow to symlink dotfiles to the home directory. The system must be idempotent, require confirmation on first run only, and include a demonstration script (`gh-open`) to verify PATH configuration.

## Technical Context

**Language/Version**: Bash 5.x (installed via Homebrew, fallback to macOS default Bash 3.2)
**Primary Dependencies**:
- Homebrew (installed if not present)
- GNU Stow (for symlinking dotfiles)
- Git (for cloning repository)
- curl (pre-installed on macOS)

**Storage**: Local filesystem - dotfiles cloned to `~/.dotfiles`, symlinks created in home directory via Stow
**Testing**: Bash unit tests (bats-core), integration tests on clean macOS VM
**Target Platform**: macOS 12+ (Monterey and later)
**Project Type**: Single (shell scripts and configuration files)
**Performance Goals**: Complete setup in <30 minutes on fresh Mac with stable internet
**Constraints**:
- Must work on fresh macOS with no developer tools installed
- Must be idempotent (safe to run multiple times)
- Must preserve existing configurations when updating
- Installation script must be remotely executable via curl | bash

**Scale/Scope**:
- Support ~20-50 Homebrew packages in Brewfile
- ~10-20 utility scripts
- Configuration files for common tools (git, shell, gem, etc.)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Applicable Principles

**Code Quality Standards**: ✅ PASS
- Shell scripts will use ShellCheck for linting
- Clear naming conventions for scripts and functions
- Documentation required for all public scripts
- No security vulnerabilities (input validation, no eval of untrusted data)

**Test-Driven Development**: ⚠️ ADAPTED FOR SHELL SCRIPTING
- Unit tests using bats-core for core functions
- Integration tests on fresh macOS installations
- Target 80% coverage for setup logic
- **Note**: Pure TDD workflow adapted for shell scripting context
- Tests will validate idempotency, error handling, and PATH configuration

**User Experience Consistency**: ✅ PASS
- Consistent error messages with actionable guidance
- Progress feedback during installation
- Clear confirmation prompts on first run
- Predictable behavior (idempotent operations)

**Performance Requirements**: ✅ PASS
- Setup completes in <30 minutes (meets spec requirement)
- No blocking operations without progress feedback
- Graceful handling of slow network conditions

**Observability & Monitoring**: ⚠️ ADAPTED FOR LOCAL TOOL
- Structured logging to setup log file
- Error messages written to stderr with context
- Success/failure exit codes
- **Note**: Production monitoring (Sentry, metrics) not applicable to local setup tool

### Quality Gates Status

1. **Automated Tests**: Will implement with bats-core ✅
2. **Code Coverage**: Target 80% for setup logic ✅
3. **Linting & Formatting**: ShellCheck enforcement ✅
4. **Type Checking**: N/A (Bash is untyped) ⚠️
5. **Security Scanning**: Manual review for command injection, path traversal ✅
6. **Performance Budget**: <30 minute setup time ✅
7. **Accessibility Audit**: N/A (CLI tool) ⚠️
8. **Code Review**: Standard PR process ✅
9. **Constitution Compliance**: See adaptations above ✅

### Justification for Adaptations

This is a local development tool (dotfiles setup) rather than a production service, so some constitution principles are adapted:

- **TDD**: Using adapted workflow suitable for shell scripting (bats-core tests, integration tests on VMs)
- **Observability**: Local logging instead of distributed tracing/metrics
- **Type Safety**: N/A for Bash scripting
- **Accessibility**: CLI tool output to terminal (standard shell accessibility applies)

**Verdict**: ✅ PROCEED - Adaptations are justified for shell scripting domain

## Project Structure

### Documentation (this feature)

```text
specs/001-dotfiles-setup/
├── plan.md              # This file
├── research.md          # Phase 0 - GNU Stow, Homebrew API, idempotency patterns
├── data-model.md        # Phase 1 - Configuration state model
├── quickstart.md        # Phase 1 - Quick installation guide
├── contracts/           # Phase 1 - Setup script interface contracts
└── tasks.md             # Phase 2 - Implementation tasks (not yet created)
```

### Source Code (repository root)

```text
# Installation entry point
install.sh                 # Remote installation script (curl | bash entry point)

# Core setup infrastructure
.dotfiles/
├── setup.sh              # Main setup orchestrator
├── lib/
│   ├── homebrew.sh       # Homebrew installation and Brewfile processing
│   ├── stow.sh           # GNU Stow operations for symlinking
│   ├── config.sh         # Global configuration management (gem, git, etc.)
│   ├── utils.sh          # Common utilities (logging, confirmation, checks)
│   └── state.sh          # State tracking (first run vs update detection)
├── Brewfile              # Homebrew package definitions
└── config/               # Configuration files to be stowed
    ├── git/
    │   └── .gitconfig
    ├── gem/
    │   └── .gemrc
    └── shell/
        ├── .bashrc
        └── .zshrc

# Utility scripts (to be added to PATH)
bin/
└── gh-open               # Example script: open current git branch in browser

# Testing
tests/
├── unit/
│   ├── test_homebrew.bats
│   ├── test_stow.bats
│   ├── test_config.bats
│   └── test_state.bats
└── integration/
    └── test_full_setup.bats

# Development tools
.shellcheckrc             # ShellCheck linting configuration
```

**Structure Decision**: Single project structure is appropriate for a dotfiles repository. The `.dotfiles/` directory contains setup scripts and libraries, while `bin/` contains user-facing utility scripts. Configuration files live in `config/` and are symlinked to home directory via Stow. The remote `install.sh` is the entry point that bootstraps the setup process.

## Complexity Tracking

No constitution violations requiring justification.

---

## Phase 0: Research (Complete ✅)

Research findings documented in [research.md](research.md):

- **GNU Stow**: Symlink management patterns, idempotency, conflict handling
- **Homebrew**: Non-interactive installation, Brewfile patterns, environment setup
- **Bash Install Scripts**: curl | bash security, first-run detection, error handling

**Key Decisions**:
- Use GNU Stow for declarative symlink management
- Follow Homebrew's official installation pattern
- Two-stage bootstrap (remote install.sh + local setup.sh)
- Flag-based state tracking for first run detection

---

## Phase 1: Design & Contracts (Complete ✅)

Design artifacts created:

1. **[data-model.md](data-model.md)**: State tracking, entities, relationships
   - Installation state schema
   - Repository, package, configuration entities
   - Platform detection and environment configuration
   - Log format and state persistence

2. **[contracts/script-interfaces.md](contracts/script-interfaces.md)**: Script APIs
   - Function signatures and contracts for all libraries
   - Exit codes and error handling conventions
   - Environment variable contracts
   - Logging format specification

3. **[quickstart.md](quickstart.md)**: User documentation
   - One-command installation
   - Verification steps
   - Customization guide
   - Troubleshooting common issues

**Key Interfaces**:
- `install.sh`: Remote bootstrap (curl | bash entry point)
- `setup.sh`: Main orchestrator
- Libraries: `homebrew.sh`, `stow.sh`, `config.sh`, `state.sh`, `utils.sh`
- Utility: `gh-open` script (demonstrates PATH integration)

---

## Constitution Re-Check (Post-Design)

### Quality Gates Assessment

All design decisions continue to align with constitution principles:

1. **Code Quality**: ✅
   - ShellCheck will be configured for linting
   - Clear function contracts documented
   - Security patterns researched and documented

2. **Testing**: ✅
   - Unit test framework identified (bats-core)
   - Integration test approach defined
   - Idempotency tests planned

3. **User Experience**: ✅
   - Clear error messages in contracts
   - Progress feedback specified
   - Confirmation flows documented

4. **Performance**: ✅
   - <30 minute setup time maintained
   - `--no-upgrade` flag for faster installs
   - Progress indicators planned

5. **Observability**: ✅
   - JSON logging format defined
   - Error tracking via exit codes
   - State file for persistence

**Verdict**: ✅ All gates continue to pass. Ready for Phase 2 (Tasks).
