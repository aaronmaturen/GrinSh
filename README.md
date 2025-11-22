# grinsh

A conversational shell for macOS.

---

## Overview

You open a terminal. Instead of a prompt, there's a conversation. You say what you want, grinsh does it. No flags, no man pages, no syntax to remember.

```
> what's using port 8080
> compress the projects folder
> find that pdf I downloaded last week
> quit slack
> turn the volume down
```

---

## Features

- **Natural language interface**: Just say what you want in plain English
- **Built-in macOS tools**: Native Swift APIs for files, apps, system operations
- **Auto-installing CLI tools**: Discovers and installs tools via Homebrew on demand
- **Conversation history**: Remembers context across your session
- **Touch ID support**: Privileged operations use native macOS authentication
- **Escape hatch**: Run raw commands with `!command` or `exit` to quit

---

## Installation

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Homebrew (recommended, for CLI tool installation)
- Claude API key from [console.anthropic.com](https://console.anthropic.com)

### Build from source

```bash
# Clone the repository
git clone https://github.com/yourusername/grinsh.git
cd grinsh

# Build release binary
swift build -c release

# Install binary
sudo cp .build/release/grinsh /usr/local/bin/grinsh

# Create config file
cp .grinshrc.example ~/.grinshrc

# Edit config and add your Claude API key
nano ~/.grinshrc
```

### Set as default shell (optional)

```bash
# Add to valid shells
echo "/usr/local/bin/grinsh" | sudo tee -a /etc/shells

# Set as default shell
chsh -s /usr/local/bin/grinsh

# To revert back to zsh
chsh -s /bin/zsh
```

---

## Configuration

Edit `~/.grinshrc`:

```toml
# Your Claude API key from console.anthropic.com
api_key = "sk-ant-..."

# Claude model to use
model = "claude-sonnet-4-20250514"

# Number of conversation messages to keep in context
context_limit = 50
```

---

## Usage

### Basic Commands

```bash
# Start grinsh
grinsh

# Natural language requests
> compress the downloads folder
> what's my battery status
> launch Safari
> find files named "report" in Documents

# Raw shell commands (escape hatch)
> !ls -la
> !git status

# Clear conversation history
> clear

# Exit
> exit
```

### Example Interactions

**File operations:**
```
> list files in ~/Documents
> copy report.pdf to ~/Desktop
> move old-project to trash
```

**App management:**
```
> quit Chrome
> launch Terminal
> hide Slack
```

**System operations:**
```
> turn volume to 50%
> show battery status
> check wifi connection
```

**CLI tools (auto-installed via Homebrew):**
```
> compress videos folder with tar
(grinsh will install tar if needed, then compress the folder)

> convert video.mp4 to gif
(grinsh will install ffmpeg if needed, then convert the video)

> what process is using port 3000
(grinsh will install lsof if needed, then show the process)
```

---

## Architecture

**Language:** Swift
**Platform:** macOS only (drop-in shell via `chsh`)
**LLM:** Claude API
**Package manager:** Homebrew (for discovering and installing CLI tools)

### Core Components

- **main.swift** - Entry point, readline loop, signal handling
- **Agent.swift** - Claude API integration, tool dispatch
- **Config.swift** - Configuration file parsing
- **Context.swift** - Conversation history management
- **Database.swift** - SQLite wrapper for persistent storage
- **Homebrew.swift** - Homebrew integration for CLI tools

### Tools

**Built-in tools** (native macOS APIs):
- **Files**: list, read, write, copy, move, delete, trash, search
- **Apps**: list, launch, quit, hide, activate
- **System**: volume, brightness, battery, wifi, disk space
- **Clipboard**: get, set, clear
- **Spotlight**: search files and apps
- **Auth**: Touch ID / password authentication for privileged ops

**Learned tools** (CLI wrappers):
- Any command-line tool available via Homebrew
- Automatically discovered, installed, and cached
- Examples: ffmpeg, git, tar, lsof, jq, imagemagick

---

## Storage

**~/.grinshrc** - Configuration file (TOML)

**~/.grinsh/grinsh.db** - SQLite database containing:
- Conversation history
- Learned CLI tools and their usage
- Homebrew package cache
- User preferences
- Command history

---

## Shell Requirements

grinsh implements a valid login shell:
- Listed in `/etc/shells`
- Handles `-l` flag (login shell)
- Handles `-c "command"` (non-interactive execution)
- Clean exit handling
- Signal handling (SIGINT, SIGTERM, SIGTSTP)

---

## Development

### Project Structure

```
grinsh/
├── Package.swift
├── Sources/
│   ├── main.swift
│   ├── Agent.swift
│   ├── Config.swift
│   ├── Context.swift
│   ├── Database.swift
│   ├── Homebrew.swift
│   └── Tools/
│       ├── Protocol.swift
│       ├── FileSystem.swift
│       ├── Apps.swift
│       ├── System.swift
│       ├── Clipboard.swift
│       ├── Spotlight.swift
│       ├── Auth.swift
│       └── Learned.swift
└── .grinshrc.example
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run without installing
.build/debug/grinsh

# Clean build
swift package clean
```

### Testing

```bash
# Run tests (when test suite is added)
swift test
```

---

## Roadmap

Future enhancements:
- Voice input (macOS dictation or Whisper)
- Calendar/Reminders integration (EventKit)
- Shortcuts integration (run shortcuts by name)
- Enhanced memory across sessions
- Local model option (Ollama) for offline/privacy
- Customizable tool plugins

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

---

## License

MIT License - See LICENSE file for details

---

## Credits

Built with:
- Swift
- [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- [Yams](https://github.com/jpsim/Yams)
- Claude API by Anthropic

---

**grinsh** - A conversational shell where you talk instead of type commands.
