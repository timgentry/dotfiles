# Feature Specification: Dotfiles Setup Command

**Feature Branch**: `001-dotfiles-setup`
**Created**: 2026-02-12
**Status**: Draft
**Input**: User description: "this is a dotfiles folder. It enables us to set up new macs very quickly, by providing Brewfile(s), useful utility scripts (adding them to the path), global config (e.g. gem install --no-doc equivalent). We need to be able to run a command that downloads the repo and sets it up"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh Mac Setup (Priority: P1)

A user receives a new Mac computer and wants to configure it to their preferred development environment with all necessary tools, utilities, and configurations in a single automated process.

**Why this priority**: This is the primary use case for the dotfiles system. Setting up a new machine is time-consuming and error-prone when done manually. This story delivers immediate value by automating the most critical setup tasks.

**Independent Test**: Can be fully tested by running the setup command on a fresh macOS installation and verifying that all essential tools are installed, utilities are in the PATH, and global configurations are applied.

**Acceptance Scenarios**:

1. **Given** a new Mac with only macOS installed, **When** user runs the dotfiles setup command, **Then** the repository is downloaded and all Brewfile dependencies are installed
2. **Given** a new Mac with only macOS installed, **When** the setup command completes, **Then** all utility scripts are accessible via PATH
3. **Given** a new Mac with only macOS installed, **When** the setup command completes, **Then** global configurations (like gem install settings) are applied system-wide

---

### User Story 2 - Updating Existing Setup (Priority: P2)

A user with an already-configured Mac wants to update their dotfiles configuration to incorporate new tools, scripts, or configuration changes from the repository.

**Why this priority**: Users need to keep their environment up-to-date as the dotfiles repository evolves. This enables continuous improvement without manual re-configuration.

**Independent Test**: Can be tested by running the setup command on a Mac that already has dotfiles installed and verifying that new additions are applied without breaking existing configurations.

**Acceptance Scenarios**:

1. **Given** a Mac with existing dotfiles setup, **When** user runs the setup command again, **Then** new Brewfile entries are installed without reinstalling existing packages
2. **Given** a Mac with existing dotfiles setup, **When** user runs the setup command again, **Then** updated utility scripts replace old versions while preserving functionality
3. **Given** a Mac with existing dotfiles setup, **When** user runs the setup command again, **Then** configuration changes are applied without data loss

---

### User Story 3 - Recovery from Configuration Issues (Priority: P3)

A user experiences configuration problems or accidentally breaks their environment and wants to restore their setup to a known good state.

**Why this priority**: While less frequent than initial setup or updates, recovery is critical when needed. This provides a safety net for users.

**Independent Test**: Can be tested by intentionally breaking specific configurations and verifying that running the setup command restores them to the correct state.

**Acceptance Scenarios**:

1. **Given** a Mac with corrupted PATH configuration, **When** user runs the setup command, **Then** PATH is restored to include all utility scripts
2. **Given** a Mac with missing or corrupted global gem configuration, **When** user runs the setup command, **Then** gem settings are restored to dotfiles defaults

---

### Edge Cases

- What happens when the user has no internet connection during setup?
- What happens when Homebrew is already installed but with conflicting packages?
- What happens when disk space is insufficient for all Brewfile dependencies?
- What happens when the repository URL is inaccessible or the repo is private?
- What happens when utility scripts conflict with existing system commands?
- What happens when running the setup command with insufficient permissions?
- What happens when setup is interrupted mid-process (power failure, force quit)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a single command that downloads the dotfiles repository to the local machine
- **FR-002**: System MUST install all dependencies listed in Brewfile(s) automatically
- **FR-003**: System MUST add utility scripts to the system PATH so they are globally accessible
- **FR-004**: System MUST apply global configurations (such as gem install --no-doc settings) system-wide
- **FR-005**: System MUST be idempotent - running the command multiple times should safely update the configuration without errors
- **FR-006**: System MUST verify prerequisites (such as macOS compatibility) before beginning setup
- **FR-007**: System MUST provide progress feedback during the setup process
- **FR-008**: System MUST handle errors gracefully and provide clear error messages when setup fails
- **FR-009**: System MUST preserve existing user data and configurations when updating
- **FR-010**: System MUST require user confirmation before making system-wide changes on first run, but run automatically without confirmation on subsequent updates

### Key Entities

- **Dotfiles Repository**: Contains Brewfile(s), utility scripts, and configuration files that define the desired system state
- **Brewfile**: Lists Homebrew packages, casks, and taps to be installed on the system
- **Utility Scripts**: Executable scripts that provide development/productivity utilities
- **Global Configurations**: System-wide settings like gem install options, shell configurations, git settings

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can set up a fresh Mac from unboxing to fully configured development environment in under 30 minutes
- **SC-002**: The setup command completes successfully on 95% of fresh macOS installations without manual intervention
- **SC-003**: Users can access all utility scripts immediately after setup without manual PATH configuration
- **SC-004**: Running the setup command on an already-configured system completes without errors or data loss
- **SC-005**: Users report 80% reduction in time spent on new Mac setup compared to manual configuration

## Scope *(mandatory)*

### In Scope

- Single command execution that handles download and setup
- Installation of Homebrew packages via Brewfile(s)
- Adding utility scripts to PATH
- Applying global configurations for common tools (gem, git, shell)
- Support for macOS systems
- Idempotent execution (safe to run multiple times)
- Error handling and user feedback
- Documentation for the setup command

### Out of Scope

- Support for non-macOS operating systems (Linux, Windows)
- Interactive configuration wizards or customization during setup
- Backup of existing configurations before changes
- Uninstallation or rollback functionality
- User-specific application preferences (browser bookmarks, app-specific settings)
- Cloud synchronization of dotfiles
- Automatic updates or scheduled runs

## Assumptions *(mandatory)*

- Users have administrative privileges on their Mac
- Users have a stable internet connection during setup
- The dotfiles repository is publicly accessible or users have appropriate credentials
- macOS version is compatible with specified Homebrew packages
- Users are familiar with command-line execution
- Homebrew is the primary package manager for macOS (will be installed if not present)
- Default shell is bash or zsh
- Users want the opinionated configuration defined in the dotfiles repository

## Dependencies

- Homebrew package manager (will be installed if not present)
- Git (for cloning the repository)
- macOS operating system
- Internet connectivity for downloading packages
- Administrative permissions for system-wide changes

## Risks & Mitigations

### Risk 1: Conflicts with Existing System Configuration
**Impact**: High - Could break existing user setup
**Mitigation**: Implement idempotent operations and check for conflicts before applying changes. Provide clear warnings about what will be modified.

### Risk 2: Large Download Size for All Packages
**Impact**: Medium - Could take excessive time or fail on slow connections
**Mitigation**: Provide progress indicators and allow setup to resume if interrupted. Consider optional package groups.

### Risk 3: Breaking Changes in Homebrew Packages
**Impact**: Medium - Updates could introduce incompatible versions
**Mitigation**: Version pin critical packages in Brewfile. Document known compatibility issues.

### Risk 4: Insufficient Disk Space
**Impact**: Medium - Setup could fail partway through
**Mitigation**: Check available disk space before beginning installation and provide clear error message with space requirements.
