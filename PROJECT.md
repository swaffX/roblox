# Neurovia AI Coder - Complete Project Documentation

> 🤖 Pure AI-Driven Coding Assistant for Roblox Studio

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Quick Start](#quick-start)
4. [Project Structure](#project-structure)
5. [Architecture](#architecture)
6. [Development](#development)
7. [Configuration](#configuration)
8. [API Integration](#api-integration)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)

---

## 🎯 Overview

Neurovia AI Coder is a Roblox Studio plugin that provides AI-powered coding assistance through natural language interaction.

### Key Capabilities
- ❌ **No Keywords Required** - Natural language understanding
- ✅ **Automatic Code Application** - Instant integration
- 🧠 **Context-Aware** - Full project analysis
- 🚀 **Real-time Generation** - Pure AI, no templates
- 🎨 **Modern UI** - Professional dark theme

### Supported AI Providers
- OpenAI (GPT-4, GPT-3.5)
- Anthropic Claude (Claude 3)
- Google Gemini (Gemini Pro, Flash)

---

## ✨ Features

### Core Features
- Multi-AI provider support
- Workspace scanner (analyzes entire project)
- Intent analyzer (understands natural language)
- Auto-apply code (instant integration)
- Security manager (validates code)
- History management (undo/redo)
- Encrypted API key storage

### UI Features
- Modern dark theme
- Chat-based interaction
- Code preview blocks
- Provider selection
- Settings modal
- Loading indicators

---

## 🚀 Quick Start

### Prerequisites
- Roblox Studio (latest)
- Git
- Node.js & npm
- Rojo

### Installation

```powershell
# Clone
git clone https://github.com/swaffX/neurovia-roblox.git rblx
cd rblx

# Build
npm run build

# Install
npm run install-plugin
```

### First Use

1. Open Roblox Studio
2. Plugins → \"AI Coder\"
3. Configure API (⚙️ icon):
   - Select provider
   - Enter API key
   - Save
4. Start chatting!

### Examples

```
\"create a loading screen GUI\"
→ ✅ GUI created in StarterGui

\"player spawn system\"
→ ✅ Script added to ServerScriptService

\"fix the inventory GUI\"
→ ✅ Existing GUI updated
```

---

## 📁 Project Structure

```
rblx/
├── src/                    # Source code
│   ├── Plugin.server.lua   # Entry point
│   ├── Config.lua          # Configuration
│   ├── AI/                 # AI integration (6 modules)
│   ├── Core/               # Core ops (5 modules)
│   ├── UI/                 # Interface (3 modules)
│   └── Utils/              # Utilities (5 modules)
├── assets/locales/         # Translations (EN/TR)
├── tests/                  # Test files
├── build.bat               # Build script
├── package.json            # NPM config
└── default.project.json    # Rojo config
```

### Source Modules

**AI/** - AI Integration
- APIManager.lua - Multi-provider orchestration
- PromptBuilder.lua - Context-aware prompts
- ResponseParser.lua - Code extraction
- OpenAIProvider.lua, ClaudeProvider.lua, GeminiProvider.lua

**Core/** - Core Operations
- CodeAnalyzer.lua - Semantic analysis
- WorkspaceManager.lua - Instance CRUD (25+ types)
- SecurityManager.lua - Code validation
- DiffEngine.lua - Code diff display
- HistoryManager.lua - Undo/redo

**UI/** - User Interface
- MainUI.lua - Chat interface
- Components.lua - Reusable components
- Themes.lua - Color themes

**Utils/** - Utilities
- Logger.lua, Storage.lua, Encryption.lua, HTTPClient.lua, Localization.lua

---

## 🏗️ Architecture

### Data Flow

```
User Input (Natural Language)
    ↓
PromptBuilder (scan workspace, build context)
    ↓
APIManager (route to AI provider)
    ↓
ResponseParser (extract code, deduplicate)
    ↓
SecurityManager (validate safety)
    ↓
WorkspaceManager (create/update instances)
    ↓
MainUI (display result)
```

### Key Improvements

**Hash-Based Deduplication** ✅
- Prevents duplicate object creation
- Normalizes whitespace before comparison
- Guarantees single copy per request

**Generic Instance Creation** ✅
- Supports 25+ Roblox types (Part, Model, GUI, Scripts)
- Smart parent detection
- Property application

**Semantic Analysis** ✅
- Detects systems (GameManager, UISystem, etc.)
- Identifies patterns (MVC, OOP, Event-driven)
- Extended context (20+ scripts)

---

## 💻 Development

### Commands

```powershell
npm run build           # Build plugin
npm run dev             # Build + install
npm run watch           # Watch mode (Rojo)
npm run clean           # Clean artifacts
```

### Workflow

1. Edit src/ files
2. Run 
pm run build
3. Run 
pm run install-plugin
4. Restart Roblox Studio
5. Test changes

### Watch Mode

```powershell
# Terminal 1
npm run watch

# In Studio: Plugins → Rojo → Connect
# Changes sync automatically
```

---

## ⚙️ Configuration

### Config.lua

```lua
Config = {
    AI_PROVIDERS = {
        OPENAI = \"OpenAI\",
        CLAUDE = \"Claude\",
        GEMINI = \"Gemini\"
    },
    
    DEFAULT_MODELS = {
        OPENAI = \"gpt-4-turbo\",
        CLAUDE = \"claude-3-sonnet-20240229\",
        GEMINI = \"gemini-2.5-flash\"
    },
    
    DEBUG = {
        ENABLED = false,
        LOG_LEVEL = \"INFO\"
    }
}
```

### Custom System Prompts

Edit Config.SYSTEM_PROMPTS to customize AI behavior.

---

## 🔌 API Integration

### Get API Keys

- **OpenAI**: https://platform.openai.com/api-keys (format: sk-...)
- **Claude**: https://console.anthropic.com/ (format: sk-ant-...)
- **Gemini**: https://makersuite.google.com/app/apikey (alphanumeric)

### Storage

- Keys encrypted with AES-256
- Stored in PluginSettings
- Never logged or transmitted (except to APIs)

---

## 🐛 Troubleshooting

### Plugin Not Visible

1. Close Studio completely
2. Check file: %LOCALAPPDATA%\\Roblox\\Plugins\\AI-Coder-Plugin.rbxm
3. Verify size (~46 KB)
4. Reopen Studio

### API Errors

1. Verify key format
2. Check internet connection
3. Enable debug mode
4. Check Output window

### Duplicate Objects (FIXED ✅)

- Hash-based deduplication now prevents this
- If still occurs, report on GitHub

### Build Errors

1. Check Rojo installation: ojo --version
2. Verify default.project.json
3. Run 
pm run clean then 
pm run build

---

## 🤝 Contributing

1. Fork repository
2. Create branch: git checkout -b feature/name
3. Commit: git commit -m \"feat: description\"
4. Push: git push origin feature/name
5. Open Pull Request

### Commit Convention

- eat: new feature
- ix: bug fix
- chore: maintenance
- docs: documentation

---

## 📄 License

MIT License

---

## 👥 Team

**swxff** - Creator & Lead Developer

---

## 🙏 Acknowledgments

- OpenAI, Anthropic, Google for APIs
- Roblox community
- All contributors

---

**⭐ Star if useful!**
