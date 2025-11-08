# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

---

## Project Overview

**Neurovia AI Coder** is a Roblox Studio plugin that provides AI-powered coding assistance. It uses a modular Lua architecture with Rojo for build management and supports automatic code syncing via watch mode.

---

## Quick Setup for New Contributors

### First-Time Setup (Run Once)

```powershell
# 1. Install dependencies
npm install

# 2. Install Rojo plugin for auto-sync
setup-watch.bat

# 3. Build and install plugin
npm run build
npm run install-plugin
```

### Daily Development Workflow

```powershell
# Start watch mode (recommended for development)
npm run watch

# Then in Roblox Studio:
# Plugins → Rojo → Connect to localhost:34872
# Now code changes sync automatically!
```

---

## Common Commands

### Building & Installation

```powershell
# Build plugin only
npm run build

# Build + install to Roblox Studio
npm run dev

# Install plugin (after manual build)
npm run install-plugin

# Clean build artifacts
npm run clean
```

### Development Modes

```powershell
# Watch mode (automatic sync - 35x faster!)
npm run watch
# Keep this running, connect Studio to localhost:34872

# Manual mode (requires Studio restart each time)
npm run build
npm run install-plugin
# Restart Roblox Studio
```

### Testing in Studio

After changes:
1. If using watch mode: Changes appear instantly ✅
2. If manual mode: Rebuild, reinstall, restart Studio

---

## Project Structure

```
src/
├── Plugin.server.lua    # Entry point, loads all modules
├── Config.lua           # Global configuration (API endpoints, models, debug settings)
│
├── AI/                  # AI Integration Layer
│   ├── APIManager.lua        # Multi-provider orchestration
│   ├── PromptBuilder.lua     # Context-aware prompt generation
│   ├── ResponseParser.lua    # Code extraction with deduplication
│   ├── OpenAIProvider.lua    # OpenAI API wrapper
│   ├── ClaudeProvider.lua    # Anthropic Claude API wrapper
│   └── GeminiProvider.lua    # Google Gemini API wrapper
│
├── Core/                # Core Operations
│   ├── CodeAnalyzer.lua      # Semantic analysis, system detection
│   ├── WorkspaceManager.lua  # Instance CRUD (25+ Roblox types)
│   ├── SecurityManager.lua   # Code validation and safety checks
│   ├── DiffEngine.lua        # Code diff visualization
│   └── HistoryManager.lua    # Undo/redo functionality
│
├── UI/                  # User Interface
│   ├── MainUI.lua           # Chat interface, main window
│   ├── Components.lua       # Reusable UI components
│   └── Themes.lua           # Color themes and styling
│
└── Utils/               # Utility Modules
    ├── Logger.lua           # Logging system with levels
    ├── Storage.lua          # Persistent storage (PluginSettings)
    ├── Encryption.lua       # API key encryption (AES-256)
    ├── HTTPClient.lua       # HTTP request handler
    └── Localization.lua     # i18n support (EN/TR)
```

---

## Architecture Notes

### Build Process
- **Rojo** reads default.project.json and combines all src/*.lua files into plugin.rbxm (binary)
- Binary is copied to %LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm
- Studio loads the plugin on startup

### Module Loading
- Plugin.server.lua is the entry point (runs first)
- All modules are ModuleScripts accessed via equire(script.Path.To.Module)
- Config is loaded first, then Utils, Core, AI, UI in order

### Key Patterns
- **Hash-based deduplication** in ResponseParser prevents duplicate object creation
- **Generic instance creation** in WorkspaceManager supports 25+ Roblox types
- **Semantic analysis** in CodeAnalyzer detects systems (MVC, OOP patterns)
- **Multi-AI support** via provider pattern in AI/ modules

---

## Making Changes

### Adding a New Feature

1. **Create new module** (e.g., src/Utils/NewFeature.lua):
   ```lua
   local NewFeature = {}
   
   function NewFeature:doSomething()
       return "Hello from new feature!"
   end
   
   return NewFeature
   ```

2. **Use in Plugin.server.lua** or other modules:
   ```lua
   local NewFeature = require(script.Utils.NewFeature)
   NewFeature:doSomething()
   ```

3. **Test**:
   - If watch mode: Save and changes appear instantly
   - If manual: 
pm run build && npm run install-plugin then restart Studio

### Modifying Existing Code

1. Edit the relevant .lua file in src/
2. Save changes
3. Test in Studio (auto-sync if watch mode active)

### Configuration Changes

Edit src/Config.lua for:
- API endpoints
- Default AI models
- Debug settings
- UI configuration
- System prompts

### Testing

```powershell
# In Roblox Studio after changes:
# 1. Open Plugins → AI Coder
# 2. Test the feature
# 3. Check Output window for logs (if debug enabled)
```

---

## Debugging

### Enable Debug Mode

Edit src/Config.lua:
```lua
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG",
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

Rebuild and check Studio Output window for detailed logs.

### Common Issues

**Plugin not appearing in Studio:**
- Restart Studio completely
- Check file exists: %LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm
- Verify file size (~46 KB, not 0 bytes)

**Watch mode not syncing:**
- Ensure 
pm run watch is running
- Check Studio connection: Plugins → Rojo (should be green)
- Reconnect in Studio if needed

**Build errors:**
- Verify Rojo is installed: ojo --version
- Check default.project.json syntax
- Run 
pm run clean then rebuild

---

## Git Workflow

### Making Changes

```powershell
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes to src/ files

# 3. Test thoroughly

# 4. Commit
git add .
git commit -m "feat: description of change"

# 5. Push
git push origin feature/my-feature

# 6. Create pull request on GitHub
```

### Commit Message Format

- eat: - New feature
- ix: - Bug fix
- docs: - Documentation changes
- efactor: - Code refactoring
- chore: - Maintenance tasks

---

## Important Files

- **default.project.json** - Rojo build configuration (defines plugin structure)
- **package.json** - NPM scripts and project metadata
- **build.bat** - Build script (calls Rojo)
- **watch.bat** - Watch mode script (starts Rojo server)
- **setup-watch.bat** - Automatic Rojo plugin installer

---

## API Integration

### Supported Providers
- **OpenAI**: GPT-4, GPT-3.5
- **Anthropic**: Claude 3 (Sonnet, Opus)
- **Google**: Gemini 2.5 Flash, Gemini Pro

### API Key Management
- Keys stored encrypted in PluginSettings
- Never committed to Git (use Studio settings UI)
- Encryption via Utils/Encryption.lua (AES-256)

---

## Performance Tips

- **Use watch mode** during development (35x faster than manual)
- **Disable debug logs** in production builds
- **Test with small changes** before large refactors
- **Check Output window** for warnings/errors

---

## Documentation References

- **PROJECT.md** - Complete project documentation
- **WATCH_MODE_SETUP.md** - Watch mode setup guide
- **README.md** - Quick start and overview

---

## Need Help?

1. Check **PROJECT.md** for detailed documentation
2. Check **WATCH_MODE_SETUP.md** for setup issues
3. Enable debug mode and check Studio Output
4. Open GitHub issue with logs

---

## Warp Agent Instructions

When helping with this project:

### For New Setup
Run these commands in sequence:
```powershell
npm install
setup-watch.bat
npm run build
npm run install-plugin
```

### For Development
Start watch mode:
```powershell
npm run watch
```
Remind user to connect in Studio: Plugins → Rojo → Connect

### For Code Changes
1. Edit files in src/ directory
2. If watch mode active: Changes sync automatically
3. If manual mode: Run 
pm run build && npm run install-plugin and restart Studio

### For Troubleshooting
1. Check if Rojo is installed: ojo --version
2. Check plugin file exists: Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\AI-Coder-Plugin.rbxm"
3. Verify watch mode is running: 
etstat -ano | findstr :34872

---

**Last Updated:** 2024-11-08  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
