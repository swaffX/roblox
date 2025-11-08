# 🚀 Neurovia Coder v4.1.0 - Warp AI Setup Guide

> **Complete Setup & Development Guide for AI Assistants**

---

## 📋 Quick Reference

**Project:** Neurovia Coder v4.1.0 - AI-Powered Roblox Studio Plugin  
**File:** `C:\Users\swxff\AppData\Local\Roblox\Plugins\NeuroviaVibe.lua`  
**Lines:** 3900+  
**Status:** Production Ready ✅  
**Latest:** Quote frame system, Enhanced delete intent, Scroll position fixes

---

## 🎯 FOR WARP AI: PROJECT CONTEXT

This is a **Roblox Studio plugin** that provides an AI-powered coding assistant directly inside Roblox Studio. Think of it as "Cursor IDE for Roblox".

### Key Capabilities
- 🤖 **8 AI Models** - OpenAI, Anthropic, Gemini, xAI
- 🎨 **Modern UI** - Cursor IDE-inspired dark theme
- 💬 **2 Agent Modes** - Agent (autonomous) & Ask (research)
- 🔐 **Smart API Management** - Real-time validation, encrypted storage
- 📋 **Quote System** - Reference debug logs in chat
- 🗑️ **Smart Deletion** - AI-assisted object removal
- 📜 **Message History** - Arrow keys (↑/↓) for previous commands

---

## 🏗️ INSTALLATION GUIDE

### For Your Friend (First Time Setup)

```powershell
# === STEP 1: Install Roblox Studio ===
# Download from: https://www.roblox.com/create
# Sign in with Roblox account

# === STEP 2: Create Plugins Folder ===
$pluginsPath = "$env:LOCALAPPDATA\Roblox\Plugins"
if (!(Test-Path $pluginsPath)) {
    New-Item -ItemType Directory -Path $pluginsPath -Force
    Write-Host "✅ Plugins folder created"
}

# === STEP 3: Install Plugin ===
# Place NeuroviaVibe.lua in current directory, then run:
Copy-Item ".\NeuroviaVibe.lua" $pluginsPath -Force
Write-Host "✅ Plugin installed!"

# === STEP 4: Verify ===
if (Test-Path "$pluginsPath\NeuroviaVibe.lua") {
    $size = (Get-Item "$pluginsPath\NeuroviaVibe.lua").Length / 1KB
    Write-Host "✅ File size: $([math]::Round($size, 2)) KB"
    Write-Host "✅ Installation complete!"
} else {
    Write-Host "❌ Installation failed"
}

# === STEP 5: Open Roblox Studio ===
# Look for "Neurovia Coder" button in PLUGINS tab
# Click to open the assistant!
```

### Getting an API Key

Plugin supports 4 providers. Choose one:

**OpenAI (Recommended)**
1. Go to https://platform.openai.com/api-keys
2. Create account / Sign in
3. Click "Create new secret key"
4. Copy key (starts with `sk-...`)
5. Paste in Neurovia when selecting GPT model

**Anthropic (Claude)**
1. Go to https://console.anthropic.com/
2. Get API key (starts with `sk-ant-...`)

**Google Gemini**
1. Go to https://aistudio.google.com/app/apikey
2. Create API key (starts with `AIza...`)

**xAI (Grok)**
1. Go to https://console.x.ai/
2. Generate API key

---

## 🛠️ DEVELOPMENT WORKFLOW

### Quick Edit (Most Common)

```powershell
# 1. Open plugin file in editor
notepad "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua"

# 2. Make your changes

# 3. Save (Ctrl+S)

# 4. Restart Roblox Studio COMPLETELY
# Close ALL Studio windows, wait 3 seconds, reopen

# 5. Test your changes

# 6. If working, commit to git
Copy-Item "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua" ".\NeuroviaVibe.lua" -Force
git add NeuroviaVibe.lua
git commit -m "Your change description"
```

### Using Warp AI for Edits

When I (Warp AI) make changes:

1. I'll use `read_files` to understand current code
2. I'll use `edit_files` to make precise changes
3. You test in Roblox Studio
4. If it works, you commit
5. If issues, I'll fix based on your feedback

**Important:** Always restart Studio after code changes!

---

## 📚 CURRENT FEATURES (v4.1.0)

### UI Components

**Tab System** (Lines 462-503)
- Chat Tab: Main conversation with AI
- Debug Tab: System logs and debug info
- Smooth switching with scroll preservation

**Agent Mode Selector** (Lines 611-748)
- **Agent (∞)**: Full autonomous execution
- **Ask (💬)**: Research mode, no code execution

**Model Selector** (Lines 762-1055)
- GPT-4 Turbo, GPT-4, GPT-3.5 (OpenAI)
- Claude 3.5 Sonnet, Claude 3 Opus (Anthropic)
- Gemini 2.0 Flash, Gemini 1.5 Pro (Google)
- Grok 2 (xAI)

**Quote Frame** (Lines 1391-1496)
- Click ↩️ in debug log to quote in chat
- Appears above message input
- Sends context + your question to AI

### Intelligence Features

**Intent Detection** (Lines 2816-2862)
- Understands: create, delete, fix, modify
- Auto-routes to appropriate handler
- Falls back to AI for complex requests

**NPC Management** (Lines 3272-3330)
- Quick creation: "5 NPC oluştur"
- Auto-positioning with spacing
- Organized in Workspace/Npcs folder

**Smart Deletion** (Lines 2816-2862)
- Detects: sil, kaldır, delete, remove, temizle
- NPCs: "npcleri kaldır" removes all
- Other objects: AI-assisted search
- Confirms deletion with success message

**Code Execution** (Lines 3538-3650)
- Auto-detects: GUI, Script, or Model code
- Places in correct location automatically
- Creates LocalScript vs Script intelligently
- Tracks locations for undo functionality

---

## 🔧 CODE STRUCTURE

```
NeuroviaVibe.lua (3900+ lines)

├── Lines 1-180       : Core Setup
│   ├── Settings & Storage
│   ├── AI Providers (4 providers)
│   └── Context System
│
├── Lines 181-503     : UI Framework
│   ├── Widget & Root
│   ├── Tab System
│   └── Layout Management
│
├── Lines 504-1055    : Input Controls
│   ├── Agent Mode Dropdown
│   ├── Model Selection
│   ├── API Key Dialogs
│   └── Text Input
│
├── Lines 1056-1264   : Navigation & Layout
│   ├── Arrow Key History
│   ├── Layout Updates
│   └── API Lock Indicator
│
├── Lines 1265-1500   : Debug System
│   ├── Log Entries
│   ├── Repost Button
│   └── Quote Frame
│
├── Lines 1501-2609   : Messages & Display
│   ├── Message Bubbles
│   ├── Progress Bars
│   ├── Ask Mode
│   └── Auto-Apply
│
└── Lines 2610-3900+  : Core AI Logic
    ├── Send Function (router)
    ├── Intent Detection
    ├── Prompt Building
    ├── NPC Creation
    ├── Code Execution
    └── Error Handling
```

---

## 🎨 CUSTOMIZATION GUIDE

### Change Colors

```lua
-- Lines 21-35
local C = {
  bg = Color3.fromRGB(30,30,30),          -- Background
  accent = Color3.fromRGB(88,101,242),    -- Purple accent
  success = Color3.fromRGB(67,181,129),   -- Green (success)
  danger = Color3.fromRGB(237,66,69),     -- Red (errors)
  text = Color3.fromRGB(220,221,222),     -- Main text
  textMuted = Color3.fromRGB(140,142,145), -- Secondary text
}
```

### Add New AI Model

```lua
-- Lines 828-837 (inside showModelMenu function)
local models = {
  -- Add your model here:
  {name='Your Model Name', model='model-id', provider='ProviderName'},
  
  -- Existing models...
  {name='GPT-4 Turbo', model='gpt-4-turbo', provider='OpenAI'},
  -- ...
}
```

### Modify System Prompt

```lua
-- Lines 2857-2949 (sysPrompt variable)
local sysPrompt = [[
!!NEUROVIA CODER - ULTRA ADVANCED ASSISTANT!!
You are Neurovia AI: The ULTIMATE Roblox development assistant.

-- Add your custom instructions here
]]
```

---

## 🐛 TROUBLESHOOTING

### Issue: Plugin Not Appearing in Studio

**Solution:**
```powershell
# 1. Check file exists
Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua"

# 2. If false, reinstall
Copy-Item ".\NeuroviaVibe.lua" "$env:LOCALAPPDATA\Roblox\Plugins\" -Force

# 3. Close Studio completely
Stop-Process -Name "RobloxStudioBeta" -Force

# 4. Wait 3 seconds, then open Studio
```

### Issue: API Key Shows Lock 🔒

**Cause:** Key format doesn't match provider requirements

**Check Formats:**
- OpenAI: `sk-...` (50+ chars)
- Anthropic: `sk-ant-...` (100+ chars)
- Gemini: `AIza...` (39 chars exactly)
- xAI: Any format (20+ chars)

**Solution:** Re-enter key with correct format

### Issue: Delete Commands Not Working

**Cause:** Object name not found or misspelled

**Solutions:**
1. Use exact name from Explorer
2. Try: "show me what I can delete"
3. Use NPC shortcut: "npcleri kaldır"

### Issue: Chat Messages Disappearing

**Fixed in v4.1!** 
- Scroll position now preserved during tab switching
- Quote frame doesn't affect chat layout
- Debug repost keeps messages visible

---

## 🤖 FOR WARP AI: EDITING GUIDELINES

### Before Making Changes

1. ✅ Read `NEUROVIA_PROJECT_STATE.md` for current state
2. ✅ Use `read_files` to see current code
3. ✅ Identify exact line numbers
4. ✅ Explain what you're changing

### When User Reports Bug

1. Ask for screenshot if UI-related
2. Identify affected system (UI/AI/Logic)
3. Show current code at relevant lines
4. Explain the bug
5. Propose specific fix
6. Use `edit_files` with exact line numbers
7. Provide test steps

### Making Edits

```markdown
## Example Response Format

I'll fix [issue]. The problem is in [system] at lines [X-Y].

**Current Code:**
```lua
-- Lines X-Y
[show code]
```

**Issue:** [explain what's wrong]

**Fix:** [explain solution]

Making the change now...

[Call edit_files]

✅ Fixed! Test by:
1. [step 1]
2. [step 2]
```

### Testing Changes

```powershell
# After making edits, user should:

# 1. Close Studio completely
Stop-Process -Name "RobloxStudioBeta" -Force

# 2. Wait
Start-Sleep -Seconds 3

# 3. Open Studio
# Plugin will reload with changes

# 4. Test the specific feature
# User will report results
```

---

## 📊 PROJECT STATISTICS

```
File: NeuroviaVibe.lua
Size: ~160 KB
Lines: 3900+
Language: Lua (Roblox)
Roblox API Version: Latest (2025)

Code Distribution:
├── UI Components:    1400 lines (36%)
├── AI Integration:    900 lines (23%)
├── Message System:    600 lines (15%)
├── Logic & Routing:   700 lines (18%)
└── Utilities:         300 lines (8%)

Features:
├── AI Models:         8
├── Providers:         4
├── Agent Modes:       2
├── Tabs:              2
└── Debug Log Types:   5
```

---

## ✅ POST-INSTALL CHECKLIST

After installation, verify these work:

- [ ] Plugin appears in PLUGINS tab of Studio
- [ ] "Neurovia Coder" button clickable
- [ ] UI opens without errors
- [ ] Chat tab and Debug tab both work
- [ ] Agent mode dropdown shows ∞ and 💬
- [ ] Model dropdown shows 8 models
- [ ] Can click model to open API key dialog
- [ ] Can enter and save API key
- [ ] Lock icon 🔒 disappears when valid key entered
- [ ] Can type message and press Enter
- [ ] Message appears in chat
- [ ] Can switch between tabs smoothly
- [ ] Arrow keys (↑/↓) recall message history
- [ ] Debug logs appear when actions happen
- [ ] Can click ↩️ to repost debug log to chat

---

## 🚀 USEFUL COMMANDS

```powershell
# === INSTALLATION ===
Copy-Item ".\NeuroviaVibe.lua" "$env:LOCALAPPDATA\Roblox\Plugins\" -Force

# === BACKUP ===
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
New-Item ".\backups" -ItemType Directory -Force -ErrorAction SilentlyContinue
Copy-Item "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua" ".\backups\backup_$ts.lua"

# === RESTORE ===
Copy-Item ".\backups\backup_TIMESTAMP.lua" "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua" -Force

# === EDIT ===
code "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua"  # VS Code
notepad "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua"  # Notepad

# === VERSION CONTROL ===
Copy-Item "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua" ".\NeuroviaVibe.lua" -Force
git add .
git commit -m "Description"
git push

# === CHECK STATUS ===
Get-Item "$env:LOCALAPPDATA\Roblox\Plugins\NeuroviaVibe.lua" | 
  Select Name, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}}, LastWriteTime

# === RESTART STUDIO ===
Stop-Process -Name "RobloxStudioBeta" -Force -ErrorAction SilentlyContinue
Write-Host "Wait 3 seconds before reopening Studio..."
Start-Sleep -Seconds 3
```

---

## 📖 ADDITIONAL RESOURCES

### Documentation
- **Roblox Docs**: https://create.roblox.com/docs
- **Lua Reference**: https://www.lua.org/manual/5.1/
- **Roblox API**: https://create.roblox.com/docs/reference/engine

### AI Providers
- **OpenAI**: https://platform.openai.com/
- **Anthropic**: https://www.anthropic.com/
- **Google AI**: https://ai.google.dev/
- **xAI**: https://x.ai/

### Tools
- **VS Code**: https://code.visualstudio.com/
- **Git**: https://git-scm.com/
- **PowerShell**: Built into Windows

---

**Version:** v4.1.0  
**Status:** ✅ Production Ready  
**Last Updated:** 2025-01-08 20:36 UTC  
**Next Version:** v4.2.0 planned

**For Warp AI:** This is the COMPLETE setup and development guide. Read this + NEUROVIA_PROJECT_STATE.md before helping users. When editing code, always use exact line numbers and test in Roblox Studio.
