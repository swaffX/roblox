# 🛠️ Neurovia Coder - Debug System Documentation

**Version:** 3.1.0  
**Feature:** Real-time Debug Logging with Copy & Repost  
**Date:** 2025-01-08

---

## 📋 Overview

Neurovia Coder now includes a **dual-tab interface** with a dedicated **Debug panel** that tracks all plugin actions in real-time. This provides transparency into AI operations, error diagnosis, and development workflow.

### **Key Features**

✅ **Dual-Tab UI**: Switch between 💬 Chat and 🐛 Debug  
✅ **5 Log Types**: Info, Success, Error, Action, Warning  
✅ **Copy to Clipboard**: One-click log copying (📋 button)  
✅ **Repost to Chat**: WhatsApp-style reply system (↩️ button)  
✅ **Auto-Scroll**: Automatically scrolls to latest log  
✅ **Log Limit**: Stores max 100 logs (auto-cleans oldest)  
✅ **Modern UI**: Chat bubble style with smooth animations  

---

## 🎨 UI Design

### **Tab Bar**
```
[💬 Chat] [🐛 Debug]
```
- **Active tab**: Purple background (RGB 88,101,242), white text
- **Inactive tab**: Dark gray (RGB 35,35,40), muted text
- **Hover effect**: Smooth color transition (TweenService)

### **Debug Log Entry**
```
┌───────────────────────────────────┐
│ ⚡ ACTION             10:45:23   │
│                                   │
│ Script Created                    │
│ ClientScript (LocalScript)        │
│ created in StarterGui             │
│                                   │
│                      [📋] [↩️]   │
└───────────────────────────────────┘
```

**Components:**
- **Icon + Type**: Colored emoji + uppercase label
- **Timestamp**: HH:MM:SS format (top-right, muted)
- **Message**: Primary log message (white text)
- **Details**: Optional secondary info (muted text)
- **Buttons**: Copy (📋) and Repost (↩️) bottom-right

---

## 📊 Log Types

| Type | Icon | Color | Usage |
|------|------|-------|-------|
| **Info** | 🔵 | RGB(88,101,242) | AI requests, code extraction |
| **Success** | ✅ | RGB(67,181,129) | Successful operations (NPC created, GUI applied) |
| **Error** | ❌ | RGB(237,66,69) | Failures, compilation errors |
| **Action** | ⚡ | RGB(88,101,242) | User actions (script created, GUI applied) |
| **Warning** | ⚠️ | RGB(250,166,26) | Empty responses, potential issues |

---

## 🔍 Tracked Events

### **1. AI Operations**
- **Info**: AI request sent (`Sending request to gemini-2.5-flash`)
- **Success**: AI response received (`Received 1234 characters from AI`)
- **Warning**: Empty/short AI response
- **Error**: API errors, network failures

### **2. Code Processing**
- **Info**: Code blocks extracted (`Found 2 code block(s) in AI response`)
- **Error**: Compilation errors in GUI builder

### **3. Object Creation**
- **Success**: NPC creation (`5 NPCs created in Workspace/Npcs folder`)
- **Action**: GUI applied (`LoadingGUI added to StarterGui with 8 elements`)
- **Action**: Script created (`ClientScript (LocalScript) created in StarterGui`)
- **Error**: Creation failures

### **4. Errors**
- **Error**: AI errors, network issues
- **Error**: GUI build failures
- **Error**: Script creation failures

---

## 📋 Copy Button

**Emoji:** 📋  
**Function:** Copies log text to clipboard

**Log Format:**
```
[10:45:23] ACTION: Script Created
ClientScript (LocalScript) created in StarterGui
```

**Behavior:**
1. Click 📋 button
2. Button changes to ✓ (green checkmark)
3. Text copied to clipboard via `StudioService:CopyToClipboard()`
4. After 1 second, button reverts to 📋

**Use Cases:**
- Share logs with teammates
- Report bugs with exact timestamps
- Copy error messages for debugging

---

## ↩️ Repost Button

**Emoji:** ↩️  
**Function:** Opens WhatsApp-style repost modal

### **Repost Modal UI**

```
╔════════════════════════════════════╗
║  💬 Repost to Chat              ×  ║
╠════════════════════════════════════╣
║                                    ║
║  ┌──────────────────────────────┐ ║
║  │ [ACTION] Script Created      │ ║ (Quote box)
║  │ ClientScript (LocalScript)   │ ║
║  │ created in StarterGui        │ ║
║  └──────────────────────────────┘ ║
║                                    ║
║  ┌──────────────────────────────┐ ║
║  │ ✍️ Add your comment...      │ ║ (Comment box)
║  │                              │ ║
║  │                              │ ║
║  └──────────────────────────────┘ ║
║                                    ║
║  [        ▶️ Send        ]         ║
╚════════════════════════════════════╝
```

**Components:**
1. **Quote Box**: Original log (bordered with log type color)
2. **Comment Box**: Multiline TextBox for user comment
3. **Send Button**: Posts to Chat tab
4. **Close Button (×)**: Dismisses modal

**Workflow:**
1. User clicks ↩️ on debug log
2. Modal opens (semi-transparent backdrop)
3. Original log shown in quote box
4. User types comment (optional)
5. Click "Send" → switches to Chat tab
6. Message appears as: `📝 **Debug Log Repost**`

**Output Format:**
```
📝 **Debug Log Repost**

**Quote:** [ACTION] Script Created
ClientScript (LocalScript) created in StarterGui

**Comment:** This script has a bug, need to fix the event handler.
```

**Use Cases:**
- Ask AI to fix error from debug log
- Request clarification about logged operation
- Follow up on warnings/issues

---

## 🚀 Performance

### **Log Limit: 100 entries**

**Behavior:**
- When 101st log is added, oldest log is destroyed
- Array management: `table.remove(debugLogs, 1)`
- UI cleanup: `oldest:Destroy()`

**Memory Optimization:**
- Logs stored in array with metadata:
  ```lua
  {
    type = 'success',
    message = 'NPC Creation',
    details = '5 NPCs created...',
    instance = npcModel, -- weak reference
    timestamp = os.time()
  }
  ```
- Auto-scroll prevents canvas size overflow
- Weak references for instance tracking

---

## 🎬 Animation System

### **Hover Effects**

**Copy/Repost Buttons:**
```lua
MouseEnter → TextColor3 tween to accent/blue (0.15s)
MouseLeave → TextColor3 tween to default (0.15s)
```

**Tab Buttons:**
```lua
Active: BackgroundColor3 = RGB(88,101,242)
Inactive: BackgroundColor3 = RGB(35,35,40)
Transition: Smooth TweenService animation
```

### **Modal Animations**

**Repost Popup:**
- Backdrop fade-in: BackgroundTransparency 1 → 0.4
- Panel scale-in: Size 0 → (360,280) with Back easing
- Close animation: Scale-out then Destroy()

---

## 📐 Layout Specs

### **Debug ScrollingFrame**
```lua
Position: UDim2.new(0,10,0,52)
Size: UDim2.new(1,-20,1,-168)
BackgroundTransparency: 1
ScrollBarThickness: 6
ScrollBarImageColor3: RGB(50,50,50)
ElasticBehavior: Always
AutomaticCanvasSize: Y
```

### **Log Entry Frame**
```lua
Size: UDim2.new(1,-8,0,60) -- AutomaticSize.Y
BackgroundColor3: RGB(35,35,40)
CornerRadius: 8px
Padding: 12px (all sides)
```

### **Repost Modal**
```lua
Panel Size: 360×280px
Position: Center (0.5, 0.5)
AnchorPoint: (0.5, 0.5)
ZIndex: 1001 (backdrop: 1000)
BackgroundColor3: RGB(40,40,40)
CornerRadius: 12px
```

---

## 🧪 Testing Checklist

### **Basic Functionality**
- [ ] Debug tab switches correctly
- [ ] Logs appear in debug panel
- [ ] Timestamps are accurate (HH:MM:SS)
- [ ] Icons and colors match log type

### **Copy Function**
- [ ] Click 📋 → text copied to clipboard
- [ ] Button shows ✓ for 1 second
- [ ] Button reverts to 📋

### **Repost Function**
- [ ] Click ↩️ → modal opens
- [ ] Quote box shows original log
- [ ] Comment box accepts multiline text
- [ ] Send button switches to Chat tab
- [ ] Message appears with correct format
- [ ] × button closes modal

### **Performance**
- [ ] 100+ logs → oldest logs removed
- [ ] Auto-scroll works on new log
- [ ] No memory leaks after 200+ logs

### **Integration**
- [ ] NPC creation → success log
- [ ] GUI applied → action log
- [ ] AI error → error log
- [ ] Code extraction → info log

---

## 🐛 Troubleshooting

### **Issue: Logs not appearing**
**Solution:** Check if `debugScroll` is visible and `activeTab == 'debug'`

### **Issue: Copy button not working**
**Solution:** Verify `StudioService:CopyToClipboard()` is available (requires Roblox Studio API)

### **Issue: Repost modal behind other UI**
**Solution:** Check ZIndex values (backdrop=1000, panel=1001, children=1002)

### **Issue: Auto-scroll not working**
**Solution:** Ensure `task.defer()` is used to delay scroll until canvas size updates

---

## 📝 Code Reference

### **Key Functions**

```lua
-- Add debug log
addDebugLog(logType, message, details, relatedInstance)
-- logType: 'info' | 'success' | 'error' | 'action' | 'warning'

-- Example usage
addDebugLog('success', 'NPC Creation', string.format('%d NPCs created', count))
addDebugLog('error', 'GUI Build Failed', tostring(err))
```

### **Log Entry Locations**

| Event | Line | Log Type |
|-------|------|----------|
| NPC Created | ~2626 | success |
| NPC Failed | ~2629 | error |
| AI Request | ~2775 | info |
| AI Response | ~2788 | success |
| Empty Response | ~2791 | warning |
| Code Extracted | ~2805 | info |
| GUI Applied | ~2916 | action |
| GUI Failed | ~2920, ~2924 | error |
| Script Created | ~2969 | action |
| Script Failed | ~2973 | error |
| AI Error | ~3025 | error |
| GUI Compile Error | ~1465 | error |

---

## 🎓 Best Practices

### **For Developers**
1. **Always add logs for critical operations**
   - User actions (NPC creation, GUI application)
   - AI calls (request/response)
   - Errors (all pcall failures)

2. **Use appropriate log types**
   - `info`: Informational (code extracted, request sent)
   - `success`: Confirmed success (object created)
   - `error`: Failures requiring attention
   - `action`: User-triggered actions
   - `warning`: Non-critical issues

3. **Provide meaningful details**
   ```lua
   -- Bad
   addDebugLog('error', 'Failed')
   
   -- Good
   addDebugLog('error', 'GUI Build Failed', 
     string.format('Compile error: %s', err))
   ```

### **For Users**
1. **Use Debug tab for troubleshooting**
   - Check logs when something doesn't work
   - Look for error logs (❌) and warnings (⚠️)

2. **Repost errors to Chat for AI help**
   - Click ↩️ on error log
   - Add context in comment
   - Send to get AI assistance

3. **Copy logs for bug reports**
   - Click 📋 to copy log text
   - Paste in bug report or team chat

---

## 🚧 Future Enhancements

### **Planned Features**
- [ ] Filter logs by type (show only errors)
- [ ] Search/find in logs
- [ ] Export logs to file (.txt or .json)
- [ ] Log statistics (error count, action count)
- [ ] Collapsible log details (accordion)
- [ ] Log tags/categories
- [ ] Performance metrics (AI response time)

### **UI Improvements**
- [ ] Log grouping by time (Today, Yesterday)
- [ ] Color-coded scrollbar based on log types
- [ ] Minimap view of logs (visual timeline)
- [ ] Log importance levels (low, medium, high)

---

**End of Documentation** - Last updated: 2025-01-08 @ 11:00 UTC
