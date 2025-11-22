# Changelog

All notable changes to grinsh will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Voice input support (macOS dictation or Whisper)
- Calendar/Reminders integration (EventKit)
- Shortcuts integration
- Enhanced memory across sessions
- Local model option (Ollama) for offline mode
- Customizable tool plugins

## [1.0.0] - 2025-01-XX

### Added
- Initial release of grinsh
- Natural language command interface powered by Claude API
- Built-in macOS tools using native Swift APIs:
  - File operations (list, read, write, copy, move, delete, trash, search)
  - App management (launch, quit, hide, activate)
  - System operations (volume, brightness, battery, wifi, disk space)
  - Clipboard operations (get, set, clear)
  - Spotlight search integration
  - Touch ID authentication for privileged operations
- Auto-discovery and installation of CLI tools via Homebrew
- Conversation history with configurable context limits
- SQLite database for persistent storage:
  - Message history
  - Learned CLI tools
  - Homebrew package cache
  - User preferences
  - Command history
- TOML configuration file support (~/.grinshrc)
- Shell compatibility:
  - Support for `-l` (login shell) flag
  - Support for `-c "command"` (non-interactive execution)
  - Signal handling (SIGINT, SIGTERM, SIGTSTP)
  - Escape hatch for raw shell commands (`!command`)
- Comprehensive test suite with 100+ test cases
- GitHub Actions CI/CD pipeline:
  - Automated testing on push and pull requests
  - Automated releases on version tags
  - Code coverage reporting
  - SwiftLint integration
- Documentation:
  - README with installation and usage instructions
  - CONTRIBUTING guide for developers
  - Test documentation
  - Example configuration file

### Technical Details
- Written in Swift 5.9
- Requires macOS 13.0 or later
- Dependencies:
  - SQLite.swift for database operations
  - Yams for YAML/TOML parsing
- Universal binary supporting both ARM64 and x86_64

---

## Release Types

- **Major version** (X.0.0): Incompatible API changes or major new features
- **Minor version** (x.X.0): Backwards-compatible new features
- **Patch version** (x.x.X): Backwards-compatible bug fixes

---

## Links

- [GitHub Repository](https://github.com/yourusername/grinsh)
- [Issue Tracker](https://github.com/yourusername/grinsh/issues)
- [Releases](https://github.com/yourusername/grinsh/releases)
