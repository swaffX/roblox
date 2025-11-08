# WARP.md

This file provides complete guidance to WARP AI for working with this Roblox Studio plugin project.

---

## 🎯 Project Type

**Roblox Studio Plugin: Neurovia Coder v2.0.0** - AI-powered coding assistant with multi-provider support (OpenAI, Claude, Gemini)

**IMPORTANT: Single-File Plugin System**
This project uses a **single .lua file** deployment to avoid Rojo packaging crashes. The source code is modular (`src/` directory) but builds to one file (`neurovia-coder-full.lua`).

---

## 🚀 Complete Setup Workflow (Run This for New Contributors)

This project uses a **single-file plugin** system to avoid Rojo packaging crashes.

### Quick Install (Recommended)

```powershell
# Run install script
.\install-plugin.bat
```

### Manual Install

```powershell
# Copy plugin file to Roblox Plugins folder
Copy-Item "neurovia-coder-full.lua" "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.lua" -Force
```

**After installation:**
1. Close Roblox Studio completely (if open)
2. Open Roblox Studio
3. Go to **Plugins** tab
4. Click **"Neurovia Coder"** button
5. UI panel will open on the left
6. Configure API key with `/setkey YOUR_API_KEY`

---

## ✨ Features

**Neurovia Coder v2.0.0** includes:

### Core Features
- 🤖 **Multi-AI Support**: OpenAI GPT-4, Claude 3, Gemini Pro
- 🟥 **Modern UI**: Roblox logo, timestamps, text wrapping
- 💬 **Chat Interface**: Real-time AI conversations
- 🔒 **Secure Storage**: Encrypted API key storage
- 🌐 **Multilingual**: Turkish and English support

### AI Enhancements
- 🎯 **Intent Analyzer**: Detects user intent (create, modify, debug, explain, etc.)
- 🧠 **5-Step Thinking Process**: AI uses structured problem-solving
  1. Understand the request
  2. Analyze the context
  3. Plan the solution
  4. Implement
  5. Validate

### UI Features
- Modern dark theme
- Message bubbles with user/AI distinction
- Timestamps (HH:MM:SS)
- Auto-scrolling chat
- Provider switching (OpenAI/Claude/Gemini)
- Command system (`/setkey` for API keys)

---

## 📁 Project Structure

```
rblx/
├── neurovia-coder-full.lua   # ⭐ MAIN PLUGIN FILE (772 lines, all features)
├── install-plugin.bat        # Quick install script
├── src/                      # Source code (for reference/development)
│   ├── Plugin.server.lua     # Entry point
│   ├── Config.lua            # Configuration
│   ├── AI/                   # AI providers (6 modules)
│   ├── Core/                 # Core logic (5 modules)
│   ├── UI/                   # User interface (3 modules)
│   └── Utils/                # Utilities (5 modules)
│
├── assets/locales/           # Translation files
├── package.json              # NPM configuration (not used for plugin)
├── default.project.json      # Rojo config (not used for plugin)
├── README.md                 # Public readme
└── WARP.md                   # This file (for Warp AI)
```

**Important:** The `src/` directory is for **reference only**. The actual plugin is `neurovia-coder-full.lua` (single file).

---

## 💻 Common Commands

### Install Plugin

```powershell
# Quick install
.\install-plugin.bat

# OR manual
Copy-Item "neurovia-coder-full.lua" "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.lua" -Force
```

### Check Installation

```powershell
# Verify plugin file exists
Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.lua"

# View plugin file size
(Get-Item "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.lua").Length
```

---

## 🔧 Making Code Changes

### Typical Workflow

1. **Ensure watch mode is running**: 
pm run watch
2. **Edit files in src/ directory** (e.g., src/Config.lua)
3. **Save the file** (Ctrl+S)
4. **Changes appear instantly in Roblox Studio** ✅

### If watch mode isn't active:

```powershell
npm run build
npm run install-plugin
# Restart Roblox Studio
```

---

## ❓ Why Single-File Plugin?

**Problem:** Rojo-packaged plugins (`.rbxm` and `.rbxmx`) were causing Studio to crash during plugin loading.

**Solution:** Single `.lua` file deployment.

**Benefits:**
- ✅ **Stable**: No crashes, loads reliably
- ✅ **Simple**: Just copy one file
- ✅ **Fast**: Instant updates (no build process)
- ✅ **Git-friendly**: Easy to track changes
- ✅ **Portable**: Works on any machine

**Trade-offs:**
- ⚠️ Single file is large (~770 lines)
- ⚠️ Manual updates (but simple: just copy file)

---

## 🐛 Troubleshooting

### Plugin Not Showing in Studio

```powershell
# Check if plugin file exists
Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.lua"

# If false, run install script:
.\install-plugin.bat

# Restart Roblox Studio completely
```

### Watch Mode Not Syncing

```powershell
# Check if watch mode is running
netstat -ano | findstr :34872

# If nothing shows, start watch mode:
npm run watch

# In Studio: Plugins → Rojo → Disconnect → Connect
```

### Build Errors

```powershell
# Check Rojo is installed
rojo --version

# If error, Rojo needs installation:
# https://github.com/rojo-rbx/rojo/releases

# Clean and rebuild
npm run clean
npm run build
```

### Rojo Plugin Not in Studio

```powershell
# Download and install Rojo plugin
$url = 'https://github.com/rojo-rbx/rojo/releases/latest/download/rojo-plugin.rbxm'
$dest = "$env:LOCALAPPDATA\Roblox\Plugins\rojo-plugin.rbxm"
Invoke-WebRequest -Uri $url -OutFile 'rojo-plugin.rbxm' -UseBasicParsing
Copy-Item 'rojo-plugin.rbxm' -Destination $dest -Force

# Restart Studio
```

---

## 🎨 Common Development Tasks

### Adding a New Feature

```powershell
# 1. Create new file (e.g., src/Utils/NewFeature.lua)
New-Item -Path "src/Utils/NewFeature.lua" -ItemType File

# 2. Edit the file with feature code

# 3. If watch mode active: Changes sync automatically
# 4. If not: npm run build && npm run install-plugin
```

### Modifying Configuration

```powershell
# Edit src/Config.lua for:
# - API endpoints
# - Default AI models  
# - Debug settings
# - UI configuration

notepad src/Config.lua

# Save → Auto-syncs if watch mode active
```

### Enabling Debug Mode

Edit src/Config.lua:
```lua
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG",
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

Save and check Roblox Studio Output window for logs.

---

## 🏗️ Build System

### How It Works

1. **Rojo** reads default.project.json
2. Combines all .lua files from src/ into XML-based .rbxmx file (human-readable)
3. File is copied to %LOCALAPPDATA%\Roblox\Plugins\neurovia-coder.rbxmx
4. Roblox Studio loads the plugin on startup

### Watch Mode

- Runs Rojo server on **localhost:34872**
- Studio connects via Rojo plugin
- File changes sync automatically (no rebuild needed)
- **35x faster** than manual build/restart

---

## 📝 Git Workflow

```powershell
# Create feature branch
git checkout -b feature/my-feature

# Make changes, test

# Commit
git add .
git commit -m "feat: description"

# Push
git push origin feature/my-feature
```

### Commit Message Format
- eat: - New feature
- ix: - Bug fix
- docs: - Documentation
- efactor: - Code refactoring
- chore: - Maintenance

---

## 🔑 API Keys Setup

API keys are configured in Roblox Studio UI (not in code):

1. Open Studio
2. Open plugin: **Plugins → Neurovia Coder**
3. Click settings icon (⚙️)
4. Select provider and enter API key
5. Keys are encrypted and stored in PluginSettings

**Get API keys:**
- OpenAI: https://platform.openai.com/api-keys
- Claude: https://console.anthropic.com/
- Gemini: https://makersuite.google.com/app/apikey

---

## 🤖 Warp-Specific Instructions

### When User Says: "Set up this project"

Execute the complete setup workflow (see top of document).

### When User Says: "Start development"

```powershell
npm run watch
```

Then instruct: "Connect in Studio: Plugins → Rojo → Connect to localhost:34872"

### When User Says: "Make a change to [file]"

1. Check if watch mode is running: 
etstat -ano | findstr :34872
2. If yes: "Edit the file, save, and it will auto-sync!"
3. If no: "Start watch mode first with 
pm run watch"

### When User Reports Issues

Use troubleshooting section commands to diagnose and fix.

---

## ⚡ Quick Reference

| Task | Command |
|------|---------|
| **First-time setup** | See complete workflow at top |
| **Daily development** | 
pm run watch |
| **Manual build** | 
pm run build |
| **Install to Studio** | 
pm run install-plugin |
| **Check watch mode** | 
etstat -ano \| findstr :34872 |
|| **Check plugin file** | Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\neurovia-coder.rbxmx" |

---

## 📚 Important Notes

- **Always use watch mode** for development (35x faster)
- **Source files are in src/** - never edit the .rbxmx file directly
- **Restart Studio** if plugin doesn't appear after install
- **Reconnect Rojo** if changes stop syncing
- **Check Output window** in Studio for errors/logs

---

## 🎯 Success Criteria

Setup is successful when:
1. ✅ 
pm run watch is running without errors
2. ✅ Roblox Studio shows "Rojo" button in Plugins tab
3. ✅ Rojo shows green "Connected" status
4. ✅ Editing src/Config.lua and saving updates Studio instantly

---

**Version:** 1.0.0  
**Last Updated:** 2024-11-08  
**Status:** ✅ Production Ready
