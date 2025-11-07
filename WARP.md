# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is an AI-powered coding assistant plugin for Roblox Studio that provides intelligent code generation, editing, and analysis capabilities. It supports multiple AI providers (OpenAI GPT-4, Claude 3, Google Gemini) and allows AI models to interact directly with Roblox workspace scripts.

**Platform:** Roblox Studio Plugin (Lua/Luau)  
**Build System:** Rojo (Roblox project management tool)  
**Language:** Lua 5.1/Luau

## Development Commands

### Build and Installation
```bash
# Build the plugin (creates plugin.rbxm)
npm run build

# Watch mode for live development (requires Rojo Studio plugin)
npm run watch

# Install plugin to Roblox Studio
npm run install-plugin

# Build and install in one command
npm run dev

# Clean build artifacts
npm run clean
```

### Prerequisites
- **Rojo**: Install via `cargo install rojo` or Aftman
- Plugin location on Windows: `%LOCALAPPDATA%\Roblox\Plugins\`
- Plugin location on macOS: `~/Documents/Roblox/Plugins/`

## Architecture Overview

### Core Data Flow
The plugin follows this execution flow for AI interactions:

```
User Input → PromptBuilder → APIManager → AI Provider (OpenAI/Claude/Gemini)
                                                ↓
                                        ResponseParser
                                                ↓
                                          DiffEngine
                                                ↓
                                        PreviewPanel
                                                ↓
                                    WorkspaceManager → Script Update
                                                ↓
                                         HistoryManager
```

### Module Organization

**Entry Point:**
- `src/Plugin.lua` - Main plugin initialization, toolbar setup, and UI creation

**Core Systems** (`src/Core/`):
- `WorkspaceManager.lua` - All CRUD operations on Roblox scripts (read/write/create/delete/move)
- `SecurityManager.lua` - Malicious code detection, input validation, rate limiting
- `CodeAnalyzer.lua` - Static code analysis, dependency extraction, AI context building
- `DiffEngine.lua` - Code change preview and comparison
- `HistoryManager.lua` - Undo/Redo stack with operation snapshots

**AI Integration** (`src/AI/`):
- `APIManager.lua` - Central hub for all AI provider interactions
- `OpenAIProvider.lua` / `ClaudeProvider.lua` / `GeminiProvider.lua` - Provider-specific implementations
- `PromptBuilder.lua` - Constructs AI prompts with workspace context (✓ Implemented)
- `ResponseParser.lua` - Parses AI responses and extracts code blocks (✓ Implemented)

**Utilities** (`src/Utils/`):
- `Logger.lua` - Structured logging system
- `Storage.lua` - Persistent data storage using PluginSettings
- `Encryption.lua` - XOR + Base64 encryption for API keys
- `HTTPClient.lua` - HTTP wrapper with retry logic
- `Localization.lua` - Multi-language support (EN/TR)

**User Interface** (`src/UI/`):
- `Components.lua` - Modern UI component library (✓ Complete) - Buttons, TextBoxes, Dropdowns, Chat messages, Code blocks, Loading spinners
- `MainUI.lua` - Main application UI (✓ Complete) - Chat interface, Settings modal, History panel, Provider selection
- `Themes.lua` - Theme utilities and helpers

**Configuration:**
- `src/Config.lua` - Global configuration (API endpoints, rate limits, security settings, UI constants, theme colors)

### Key Architectural Concepts

**Security-First Design:**
All workspace operations go through `SecurityManager` which:
- Scans code for blocked patterns (e.g., `loadstring`, `getfenv`, suspicious `require()` usage)
- Enforces rate limiting (10 operations per minute per operation type)
- Validates code size limits (500KB max)
- Requires user confirmation for critical operations (delete, mass operations)
- Validates script names and paths against whitelist

**Workspace Context Generation:**
The `CodeAnalyzer` builds contextual information for AI by:
- Scanning all scripts in workspace recursively
- Extracting functions, variables, and require statements
- Calculating cyclomatic complexity
- Prioritizing important scripts by complexity and size
- Formatting workspace summaries for AI prompts

**Undo/Redo System:**
`HistoryManager` implements stack-based history with:
- Separate undo and redo stacks (max 100 operations)
- Operation types: CREATE, UPDATE, DELETE, MOVE
- Stores old and new source code for reversal
- Can create full workspace snapshots for backup/restore

**Multi-Provider AI System:**
- Each provider has isolated implementation with consistent interface
- `APIManager` routes requests to the appropriate provider
- API keys stored encrypted in PluginSettings
- Supports switching providers at runtime

## Important Technical Constraints

### Roblox Studio Limitations
- **No external libraries:** Cannot use npm packages or require external dependencies
- **Lua 5.1 + Luau extensions:** Must use compatible syntax and features
- **No file system access:** All persistence via PluginSettings API
- **HTTP restrictions:** Only HttpService available for API calls
- **Script access:** Can only read/write scripts via Instance properties

### Security Requirements
When modifying security patterns in `Config.lua > SECURITY.BLOCKED_PATTERNS`:
- These are Lua patterns (not regex)
- Used to detect potentially dangerous code before execution
- Current blocked patterns: `require%s*%(.*http`, `loadstring`, `getfenv`, `setfenv`

### Plugin Reloading
- Changes require plugin reload in Studio (or use `npm run watch` with Rojo Studio plugin)
- PluginSettings persist across sessions
- UI state does not persist (recreated on plugin open)

## Configuration Files

**`default.project.json`** - Rojo configuration defining the plugin structure  
**`package.json`** - Build scripts and metadata  
**`src/Config.lua`** - ALL runtime configuration (modify here for:)
- API endpoints and model selection
- Rate limits and timeouts
- Security patterns and thresholds
- UI dimensions and colors
- Debug logging settings

## Localization

Translations stored in `assets/locales/`:
- `en.json` - English
- `tr.json` - Turkish

Access via `Localization:get("key.path")` (e.g., `localization:get("app.title")`)

## API Key Management

API keys are:
- Encrypted using XOR + Base64 via `Encryption.lua`
- Stored in PluginSettings (per-user, per-place)
- Validated on input against provider-specific formats:
  - OpenAI: Must start with `sk-`
  - Claude: Must start with `sk-ant-`
  - Gemini: Alphanumeric string

## Debug Mode

Enable in `src/Config.lua`:
```lua
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG", -- DEBUG, INFO, WARN, ERROR
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

Logs appear in Roblox Studio Output window.

## Development Patterns

### Script Path Format
Scripts referenced as dot-separated paths: `ServerScriptService.MainScript` or `ReplicatedStorage.Modules.Utilities`

### Service Whitelist
Scripts can only be created in approved locations (enforced by `SecurityManager`):
- Workspace
- ReplicatedStorage
- ServerScriptService
- StarterPlayer
- StarterPack
- StarterGui

### Error Handling
All core operations return `(success: boolean, error: string?)` pattern. Always check success before proceeding.

### Workspace Snapshots
Use `WorkspaceManager:createSnapshot()` before bulk operations to enable rollback if needed.
