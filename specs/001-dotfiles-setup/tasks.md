# Tasks: Dotfiles Setup Command

**Input**: Design documents from `/specs/001-dotfiles-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/script-interfaces.md

**Tests**: Tests are NOT requested in this feature specification, so no test tasks are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single project structure at repository root:
- Core scripts: `.dotfiles/` directory
- Utility scripts: `bin/` directory
- Configuration files: `config/` directory
- Remote installer: `install.sh` at root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project directory structure (.dotfiles/, bin/, config/, .dotfiles/lib/)
- [X] T002 [P] Create .shellcheckrc configuration file at repository root
- [X] T003 [P] Create .gitignore file at repository root
- [X] T004 [P] Create Brewfile at repository root

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core library functions that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 [P] Implement logging functions (log_info, log_error, log_warning) in .dotfiles/lib/utils.sh
- [X] T006 [P] Implement platform detection (get_platform) in .dotfiles/lib/utils.sh
- [X] T007 [P] Implement confirmation prompt (confirm) in .dotfiles/lib/utils.sh
- [X] T008 [P] Implement dependency check (need_cmd) in .dotfiles/lib/utils.sh
- [X] T009 [P] Implement first-run detection (is_first_run) in .dotfiles/lib/state.sh
- [X] T010 [P] Implement state persistence (save_state, get_state) in .dotfiles/lib/state.sh
- [X] T011 [P] Implement Homebrew detection (detect_homebrew) in .dotfiles/lib/homebrew.sh
- [X] T012 [P] Implement shell environment configuration (configure_shell_env) in .dotfiles/lib/homebrew.sh
- [X] T013 [P] Implement Stow package checking (check_stow_installed) in .dotfiles/lib/stow.sh
- [X] T014 [P] Implement conflict handling (handle_stow_conflicts) in .dotfiles/lib/stow.sh

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Fresh Mac Setup (Priority: P1) 🎯 MVP

**Goal**: Enable a user with a new Mac to run a single command that downloads the dotfiles repository and sets up their entire development environment with Homebrew packages, utility scripts in PATH, and global configurations.

**Independent Test**: Run the installation command on a fresh macOS installation (or VM) and verify:
1. Homebrew is installed and available
2. All packages from Brewfile are installed
3. Configuration files are symlinked to home directory
4. Utility scripts (like gh-open) are accessible via PATH
5. Global configurations (gem --no-doc) are applied

### Implementation for User Story 1

- [X] T015 [US1] Create remote bootstrap script install.sh at repository root
- [X] T016 [US1] Implement Homebrew installation (install_homebrew) in .dotfiles/lib/homebrew.sh
- [X] T017 [US1] Implement Brewfile installation (install_brewfile) in .dotfiles/lib/homebrew.sh
- [X] T018 [US1] Implement single package stow (stow_package) in .dotfiles/lib/stow.sh
- [X] T019 [US1] Implement all packages stow (stow_packages) in .dotfiles/lib/stow.sh
- [X] T020 [US1] Implement git configuration (configure_git) in .dotfiles/lib/config.sh
- [X] T021 [US1] Implement gem configuration (configure_gem) in .dotfiles/lib/config.sh
- [X] T022 [US1] Implement main apply_configs function in .dotfiles/lib/config.sh
- [X] T023 [US1] Create main orchestration script .dotfiles/setup.sh that sources libraries and executes workflow
- [X] T024 [P] [US1] Create configuration directory structure (config/zsh/, config/git/, config/gem/)
- [X] T025 [P] [US1] Create .zshrc configuration file in config/zsh/.zshrc
- [X] T026 [P] [US1] Create .zprofile configuration file in config/zsh/.zprofile
- [X] T027 [P] [US1] Create .gitconfig configuration file in config/git/.gitconfig
- [X] T028 [P] [US1] Create .gemrc configuration file in config/gem/.gemrc
- [X] T029 [US1] Create gh-open utility script in bin/gh-open
- [X] T030 [US1] Populate Brewfile with essential packages (git, stow, homebrew/bundle tap)
- [X] T031 [US1] Add PATH configuration for ~/bin to shell configuration in config/zsh/.zshrc and config/zsh/.zprofile

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. A user can run the remote install command and have a complete development environment.

---

## Phase 4: User Story 2 - Updating Existing Setup (Priority: P2)

**Goal**: Enable a user with an already-configured Mac to re-run the setup command to incorporate new tools, scripts, or configuration changes without breaking existing configurations.

**Independent Test**: Run the setup command on a Mac that already has dotfiles installed, then:
1. Add a new package to Brewfile and verify it gets installed
2. Add a new utility script and verify it appears in PATH
3. Update a configuration file and verify changes are applied
4. Confirm existing packages are not reinstalled
5. Confirm no data loss or configuration corruption occurs

### Implementation for User Story 2

- [X] T032 [US2] Add idempotency checks to install.sh to skip clone if repository already exists
- [X] T033 [US2] Add git pull logic to install.sh to update existing repository
- [X] T034 [US2] Modify setup.sh to detect update mode and skip confirmation prompt on subsequent runs
- [X] T035 [US2] Add --no-upgrade flag to Brewfile installation in install_brewfile function
- [X] T036 [US2] Implement restow logic (stow -R) in stow_packages for cleaning obsolete symlinks
- [X] T037 [US2] Add timestamp tracking to save_state function for last_updated field
- [X] T038 [US2] Add version tracking to state file in save_state function

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Fresh installs work, and updates work without breaking existing setups.

---

## Phase 5: User Story 3 - Recovery from Configuration Issues (Priority: P3)

**Goal**: Enable a user to restore their setup to a known good state after configuration problems or accidental breakage.

**Independent Test**: Intentionally break specific configurations and verify recovery:
1. Delete ~/.bashrc symlink and verify setup restores it
2. Corrupt ~/.gemrc content and verify setup overwrites with correct version
3. Remove ~/bin from PATH and verify setup adds it back
4. Remove Homebrew shellenv from shell config and verify setup restores it

### Implementation for User Story 3

- [X] T039 [US3] Add validation check for shell configuration in configure_shell_env to re-add if missing
- [X] T040 [US3] Add validation check for PATH configuration to re-add ~/bin if missing
- [X] T041 [US3] Add broken symlink detection and cleanup to stow_packages before restowing
- [X] T042 [US3] Add logging of recovery actions in all validation functions
- [X] T043 [US3] Create verification function in .dotfiles/lib/config.sh to check all configurations are applied
- [X] T044 [US3] Add call to verification function at end of setup.sh workflow

**Checkpoint**: All user stories should now be independently functional. Users can install, update, and recover their dotfiles setup.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T045 [P] Add comprehensive error handling and cleanup traps to all library scripts
- [X] T046 [P] Add progress indicators to long-running operations in setup.sh
- [X] T047 [P] Create quickstart documentation validation script based on quickstart.md
- [X] T048 Run ShellCheck linting on all shell scripts
- [X] T049 Add security hardening (set -euo pipefail, input validation) to all scripts
- [X] T050 Add detailed inline documentation and function headers to all library files
- [X] T051 Create README.md at repository root with quick installation instructions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3, 4, 5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 but extends it for update scenarios
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Builds on US1/US2 to add recovery capabilities

### Within Each User Story

**User Story 1**:
- T015 (install.sh) must be created first as it's the entry point
- T016-T022 (library implementations) can proceed in parallel
- T023 (setup.sh) depends on all library functions (T016-T022)
- T024-T028 (config files) can be created in parallel
- T029 (gh-open) is independent
- T030-T031 complete the setup

**User Story 2**:
- All tasks build incrementally on US1 components

**User Story 3**:
- All tasks enhance existing functions with validation and recovery

### Parallel Opportunities

- All Setup tasks in Phase 1 can run in parallel
- All Foundational tasks marked [P] in Phase 2 can run in parallel
- Within User Story 1:
  - Tasks T016-T022 (library functions) can run in parallel
  - Tasks T024-T028 (config files) can run in parallel
- User Stories 2 and 3 could theoretically start after US1 is complete, though they build on US1

---

## Parallel Example: User Story 1 Implementation

```bash
# Launch all library implementations in parallel:
Task T016: "Implement Homebrew installation (install_homebrew) in .dotfiles/lib/homebrew.sh"
Task T017: "Implement Brewfile installation (install_brewfile) in .dotfiles/lib/homebrew.sh"
Task T018: "Implement single package stow (stow_package) in .dotfiles/lib/stow.sh"
Task T019: "Implement all packages stow (stow_packages) in .dotfiles/lib/stow.sh"
Task T020: "Implement git configuration (configure_git) in .dotfiles/lib/config.sh"
Task T021: "Implement gem configuration (configure_gem) in .dotfiles/lib/config.sh"
Task T022: "Implement main apply_configs function in .dotfiles/lib/config.sh"

# Then launch all config file creation in parallel:
Task T025: "Create .bashrc configuration file in config/bash/.bashrc"
Task T026: "Create .bash_profile configuration file in config/bash/.bash_profile"
Task T027: "Create .gitconfig configuration file in config/git/.gitconfig"
Task T028: "Create .gemrc configuration file in config/gem/.gemrc"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T014) - CRITICAL - blocks all stories
3. Complete Phase 3: User Story 1 (T015-T031)
4. **STOP and VALIDATE**: Test User Story 1 independently on a fresh Mac
5. Deploy/demo if ready

This gives you a fully functional dotfiles setup system that can install from scratch.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **MVP Ready!** (Fresh Mac setup works)
3. Add User Story 2 → Test independently → Updates work without breaking
4. Add User Story 3 → Test independently → Recovery from issues works
5. Add Polish → Production-ready with all error handling and documentation

Each story adds value without breaking previous stories.

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T014)
2. Once Foundational is done:
   - Developer A: User Story 1 (T015-T031)
   - Developer B: Start planning User Story 2 tasks
   - Developer C: Start planning User Story 3 tasks
3. After US1 complete:
   - Developer B: User Story 2 (T032-T038)
   - Developer C: User Story 3 (T039-T044)
   - Developer A: Polish (T045-T051)

---

## Summary

**Total Tasks**: 51
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 10 tasks
- Phase 3 (User Story 1): 17 tasks
- Phase 4 (User Story 2): 7 tasks
- Phase 5 (User Story 3): 6 tasks
- Phase 6 (Polish): 7 tasks

**Parallel Opportunities Identified**: 28 tasks marked [P]

**Independent Test Criteria**:
- **US1**: Install on fresh Mac, verify all components work
- **US2**: Re-run on existing install, verify updates work without breaking
- **US3**: Break configuration, verify recovery works

**Suggested MVP Scope**: User Story 1 (Phase 1 + Phase 2 + Phase 3) = 31 tasks

**Format Validation**: ✅ All tasks follow checklist format with ID, optional [P] marker, Story label (for user story phases), and file paths

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- No test tasks included as tests were not requested in feature specification
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Following constitution: idempotent operations, error handling, ShellCheck linting
