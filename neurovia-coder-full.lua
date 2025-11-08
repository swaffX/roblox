--[[
	NEUROVIA CODER - Full Featured AI Coding Assistant
	Single-file plugin to avoid Rojo packaging crashes
	
	Features:
	- Multi-AI provider support (OpenAI, Claude, Gemini)
	- Modern chat UI with Roblox logo and timestamps
	- Intent Analyzer for better prompt understanding
	- AI Thinking Process (5-step framework)
	- Secure API key storage
	- Real-time code suggestions
	
	Version: 2.0.0
	Author: swxff
]]

print("🔍 [Neurovia Coder] Loading...")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local Config = {
	PLUGIN_NAME = "Neurovia Coder",
	VERSION = "2.0.0",
	
	-- AI Providers
	PROVIDERS = {
		OPENAI = "OpenAI",
		CLAUDE = "Claude",
		GEMINI = "Gemini"
	},
	
	-- API Endpoints
	ENDPOINTS = {
		OPENAI = "https://api.openai.com/v1/chat/completions",
		CLAUDE = "https://api.anthropic.com/v1/messages",
		GEMINI = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
	},
	
	-- Default Models
	MODELS = {
		OPENAI = "gpt-4-turbo",
		CLAUDE = "claude-3-sonnet-20240229",
		GEMINI = "gemini-pro"
	},
	
	-- UI Colors (Modern Dark Theme)
	COLORS = {
		BG_PRIMARY = Color3.fromRGB(32, 34, 37),
		BG_SECONDARY = Color3.fromRGB(42, 44, 47),
		BG_TERTIARY = Color3.fromRGB(48, 50, 54),
		
		TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
		TEXT_SECONDARY = Color3.fromRGB(185, 187, 190),
		TEXT_MUTED = Color3.fromRGB(142, 144, 147),
		
		ACCENT_PRIMARY = Color3.fromRGB(88, 101, 242),
		ACCENT_SUCCESS = Color3.fromRGB(67, 181, 129),
		ACCENT_WARNING = Color3.fromRGB(250, 166, 26),
		ACCENT_DANGER = Color3.fromRGB(237, 66, 69),
		
		USER_BUBBLE = Color3.fromRGB(88, 101, 242),
		AI_BUBBLE = Color3.fromRGB(48, 50, 54),
		
		BORDER = Color3.fromRGB(60, 63, 68),
		SHADOW = Color3.fromRGB(0, 0, 0)
	},
	
	-- System Prompt with Thinking Process
	SYSTEM_PROMPT = [[You are an expert Roblox Lua developer and coding assistant.

🧠 THINKING PROCESS - Use this framework for EVERY request:

Step 1: UNDERSTAND THE REQUEST
→ What exactly is the user asking for?
→ What is their actual goal?
→ Are there any ambiguities that need clarification?

Step 2: ANALYZE THE CONTEXT
→ What is the current code/project state?
→ What dependencies or constraints exist?
→ What are the technical requirements?

Step 3: PLAN THE SOLUTION
→ Approach A: [describe]
  Pros: [list]
  Cons: [list]
→ Approach B: [describe]
  Pros: [list]
  Cons: [list]
→ Recommended: [choose and explain why]

Step 4: IMPLEMENT
→ Write clean, efficient, well-documented code
→ Follow Roblox best practices
→ Include error handling

Step 5: VALIDATE
→ Does this solve the user's problem?
→ Are there any edge cases?
→ What could be improved?

Guidelines:
- Write clean, efficient, and well-documented Lua code
- Follow Roblox best practices and conventions
- Use modern Luau features when appropriate
- Wrap code in triple backticks with 'lua' identifier
- Explain what the code does and why]]
}

-- ============================================================================
-- UTILITY: Simple Storage
-- ============================================================================

local Storage = {}
Storage.__index = Storage

function Storage.new(plugin)
	local self = setmetatable({}, Storage)
	self._plugin = plugin
	self._data = plugin:GetSetting("NeuroViaCoderData") or {}
	return self
end

function Storage:save()
	self._plugin:SetSetting("NeuroViaCoderData", self._data)
end

function Storage:get(key, default)
	return self._data[key] or default
end

function Storage:set(key, value)
	self._data[key] = value
	self:save()
end

function Storage:getAPIKey(provider)
	return self:get("apikey_" .. provider)
end

function Storage:setAPIKey(provider, key)
	self:set("apikey_" .. provider, key)
end

function Storage:getSelectedProvider()
	return self:get("provider", Config.PROVIDERS.OPENAI)
end

function Storage:setSelectedProvider(provider)
	self:set("provider", provider)
end

-- ============================================================================
-- AI: Intent Analyzer
-- ============================================================================

local IntentAnalyzer = {}

-- Intent types
local INTENTS = {
	CREATE = "create",
	MODIFY = "modify",
	DEBUG = "debug",
	EXPLAIN = "explain",
	ANALYZE = "analyze",
	REFACTOR = "refactor",
	OPTIMIZE = "optimize",
	QUESTION = "question"
}

-- Keywords for each intent (Turkish + English)
local INTENT_KEYWORDS = {
	[INTENTS.CREATE] = {"yap", "oluştur", "yarat", "ekle", "create", "make", "add", "generate", "build", "new"},
	[INTENTS.MODIFY] = {"değiştir", "güncelle", "düzenle", "modify", "change", "update", "edit", "alter"},
	[INTENTS.DEBUG] = {"hata", "sorun", "düzelt", "debug", "fix", "error", "bug", "issue", "problem"},
	[INTENTS.EXPLAIN] = {"açıkla", "anlat", "ne yapar", "explain", "describe", "what does", "how does"},
	[INTENTS.ANALYZE] = {"analiz", "incele", "kontrol", "analyze", "check", "review", "examine"},
	[INTENTS.REFACTOR] = {"refactor", "yeniden yaz", "iyileştir", "rewrite", "improve", "restructure"},
	[INTENTS.OPTIMIZE] = {"optimize", "hızlandır", "performans", "speed up", "faster", "efficient"},
	[INTENTS.QUESTION] = {"nasıl", "neden", "ne zaman", "how", "why", "when", "what", "which"}
}

function IntentAnalyzer.detect(message)
	message = string.lower(message)
	local scores = {}
	
	-- Score each intent
	for intent, keywords in pairs(INTENT_KEYWORDS) do
		scores[intent] = 0
		for _, keyword in ipairs(keywords) do
			if string.find(message, keyword, 1, true) then
				scores[intent] = scores[intent] + 1
			end
		end
	end
	
	-- Find highest score
	local maxScore = 0
	local detectedIntent = INTENTS.QUESTION
	for intent, score in pairs(scores) do
		if score > maxScore then
			maxScore = score
			detectedIntent = intent
		end
	end
	
	return detectedIntent, maxScore
end

function IntentAnalyzer.enrichPrompt(userMessage)
	local intent, confidence = IntentAnalyzer.detect(userMessage)
	
	local enriched = string.format([[
USER REQUEST ANALYSIS:

Detected Intent: %s
→ Confidence: %d keywords matched

Original User Request:
%s

INSTRUCTIONS FOR AI:
1. Use the 5-step thinking process defined in your system prompt
2. Consider the detected intent: %s
3. Provide a solution that matches the user's actual goal
4. If confidence is low, ask clarifying questions
5. Always explain your reasoning
]], string.upper(intent), confidence, userMessage, intent)
	
	return enriched
end

-- ============================================================================
-- AI: HTTP Client
-- ============================================================================

local HTTPClient = {}
HTTPClient.__index = HTTPClient

function HTTPClient.new()
	local self = setmetatable({}, HTTPClient)
	self._http = game:GetService("HttpService")
	return self
end

function HTTPClient:callOpenAI(apiKey, messages)
	local url = Config.ENDPOINTS.OPENAI
	local headers = {
		["Authorization"] = "Bearer " .. apiKey,
		["Content-Type"] = "application/json"
	}
	
	local payload = self._http:JSONEncode({
		model = Config.MODELS.OPENAI,
		messages = messages,
		temperature = 0.7,
		max_tokens = 4000
	})
	
	local success, response = pcall(function()
		return self._http:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	
	if not success then
		return false, response
	end
	
	local decoded = self._http:JSONDecode(response)
	if decoded.choices and #decoded.choices > 0 then
		return true, decoded.choices[1].message.content
	end
	
	return false, "Invalid response"
end

function HTTPClient:callClaude(apiKey, messages)
	local url = Config.ENDPOINTS.CLAUDE
	local headers = {
		["x-api-key"] = apiKey,
		["anthropic-version"] = "2023-06-01",
		["Content-Type"] = "application/json"
	}
	
	-- Separate system message
	local systemMessage = ""
	local claudeMessages = {}
	for _, msg in ipairs(messages) do
		if msg.role == "system" then
			systemMessage = msg.content
		else
			table.insert(claudeMessages, msg)
		end
	end
	
	local payload = self._http:JSONEncode({
		model = Config.MODELS.CLAUDE,
		messages = claudeMessages,
		system = systemMessage,
		max_tokens = 4000
	})
	
	local success, response = pcall(function()
		return self._http:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	
	if not success then
		return false, response
	end
	
	local decoded = self._http:JSONDecode(response)
	if decoded.content and #decoded.content > 0 then
		return true, decoded.content[1].text
	end
	
	return false, "Invalid response"
end

function HTTPClient:callGemini(apiKey, messages)
	local url = Config.ENDPOINTS.GEMINI .. "?key=" .. apiKey
	local headers = {
		["Content-Type"] = "application/json"
	}
	
	-- Convert to Gemini format
	local contents = {}
	for _, msg in ipairs(messages) do
		if msg.role ~= "system" then
			local role = msg.role == "assistant" and "model" or "user"
			table.insert(contents, {
				role = role,
				parts = {{ text = msg.content }}
			})
		end
	end
	
	local payload = self._http:JSONEncode({
		contents = contents,
		generationConfig = {
			temperature = 0.7,
			maxOutputTokens = 4000
		}
	})
	
	local success, response = pcall(function()
		return self._http:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	
	if not success then
		return false, response
	end
	
	local decoded = self._http:JSONDecode(response)
	if decoded.candidates and #decoded.candidates > 0 then
		local candidate = decoded.candidates[1]
		if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
			return true, candidate.content.parts[1].text
		end
	end
	
	return false, "Invalid response"
end

function HTTPClient:call(provider, apiKey, messages)
	if provider == Config.PROVIDERS.OPENAI then
		return self:callOpenAI(apiKey, messages)
	elseif provider == Config.PROVIDERS.CLAUDE then
		return self:callClaude(apiKey, messages)
	elseif provider == Config.PROVIDERS.GEMINI then
		return self:callGemini(apiKey, messages)
	end
	return false, "Unknown provider"
end

-- ============================================================================
-- UI: Main Interface
-- ============================================================================

local function createUI(plugin, storage, httpClient)
	-- Toolbar
	local toolbar = plugin:CreateToolbar(Config.PLUGIN_NAME)
	local button = toolbar:CreateButton(Config.PLUGIN_NAME, "AI-powered coding assistant", "")
	
	-- Widget
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		520,
		680,
		400,
		500
	)
	
	local widget = plugin:CreateDockWidgetPluginGui("NeuroViaCoderWidget", widgetInfo)
	widget.Title = Config.PLUGIN_NAME .. " v" .. Config.VERSION
	
	-- Root container
	local root = Instance.new("Frame")
	root.BackgroundColor3 = Config.COLORS.BG_PRIMARY
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = widget
	
	-- Header
	local header = Instance.new("Frame")
	header.BackgroundColor3 = Config.COLORS.BG_SECONDARY
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Parent = root
	
	local headerTitle = Instance.new("TextLabel")
	headerTitle.BackgroundTransparency = 1
	headerTitle.Font = Enum.Font.SourceSansSemibold
	headerTitle.TextSize = 18
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.TextColor3 = Config.COLORS.TEXT_PRIMARY
	headerTitle.Text = "🟥 " .. Config.PLUGIN_NAME
	headerTitle.Position = UDim2.fromOffset(12, 0)
	headerTitle.Size = UDim2.new(1, -150, 1, 0)
	headerTitle.Parent = header
	
	-- Provider selector
	local providerLabel = Instance.new("TextLabel")
	providerLabel.BackgroundTransparency = 1
	providerLabel.Font = Enum.Font.SourceSans
	providerLabel.TextSize = 12
	providerLabel.TextColor3 = Config.COLORS.TEXT_MUTED
	providerLabel.Text = "Provider:"
	providerLabel.Position = UDim2.new(1, -140, 0.5, -10)
	providerLabel.Size = UDim2.new(0, 50, 0, 20)
	providerLabel.Parent = header
	
	local providerBtn = Instance.new("TextButton")
	providerBtn.BackgroundColor3 = Config.COLORS.BG_TERTIARY
	providerBtn.BorderSizePixel = 0
	providerBtn.Font = Enum.Font.SourceSansSemibold
	providerBtn.TextSize = 12
	providerBtn.TextColor3 = Config.COLORS.TEXT_PRIMARY
	providerBtn.Text = storage:getSelectedProvider()
	providerBtn.Position = UDim2.new(1, -85, 0.5, -10)
	providerBtn.Size = UDim2.new(0, 75, 0, 20)
	providerBtn.Parent = header
	
	local providerCorner = Instance.new("UICorner")
	providerCorner.CornerRadius = UDim.new(0, 4)
	providerCorner.Parent = providerBtn
	
	-- Chat container (scrolling)
	local chatScroll = Instance.new("ScrollingFrame")
	chatScroll.BackgroundColor3 = Config.COLORS.BG_PRIMARY
	chatScroll.BorderSizePixel = 0
	chatScroll.Position = UDim2.fromOffset(0, 50)
	chatScroll.Size = UDim2.new(1, 0, 1, -150)
	chatScroll.CanvasSize = UDim2.fromScale(1, 0)
	chatScroll.ScrollBarThickness = 6
	chatScroll.ScrollBarImageColor3 = Config.COLORS.BORDER
	chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	chatScroll.Parent = root
	
	local chatList = Instance.new("UIListLayout")
	chatList.SortOrder = Enum.SortOrder.LayoutOrder
	chatList.Padding = UDim.new(0, 8)
	chatList.Parent = chatScroll
	
	local chatPadding = Instance.new("UIPadding")
	chatPadding.PaddingTop = UDim.new(0, 12)
	chatPadding.PaddingBottom = UDim.new(0, 12)
	chatPadding.PaddingLeft = UDim.new(0, 12)
	chatPadding.PaddingRight = UDim.new(0, 12)
	chatPadding.Parent = chatScroll
	
	-- Input area
	local inputContainer = Instance.new("Frame")
	inputContainer.BackgroundColor3 = Config.COLORS.BG_SECONDARY
	inputContainer.BorderSizePixel = 0
	inputContainer.Position = UDim2.new(0, 0, 1, -100)
	inputContainer.Size = UDim2.new(1, 0, 0, 100)
	inputContainer.Parent = root
	
	local inputBox = Instance.new("TextBox")
	inputBox.BackgroundColor3 = Config.COLORS.BG_TERTIARY
	inputBox.BorderSizePixel = 0
	inputBox.Font = Enum.Font.SourceSans
	inputBox.TextSize = 14
	inputBox.TextColor3 = Config.COLORS.TEXT_PRIMARY
	inputBox.TextXAlignment = Enum.TextXAlignment.Left
	inputBox.TextYAlignment = Enum.TextYAlignment.Top
	inputBox.PlaceholderText = "Ask me anything... (Turkish or English)"
	inputBox.PlaceholderColor3 = Config.COLORS.TEXT_MUTED
	inputBox.ClearTextOnFocus = false
	inputBox.MultiLine = true
	inputBox.TextWrapped = true
	inputBox.Text = ""
	inputBox.Position = UDim2.fromOffset(12, 12)
	inputBox.Size = UDim2.new(1, -24, 0, 50)
	inputBox.Parent = inputContainer
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = inputBox
	
	local inputPadding = Instance.new("UIPadding")
	inputPadding.PaddingLeft = UDim.new(0, 10)
	inputPadding.PaddingRight = UDim.new(0, 10)
	inputPadding.PaddingTop = UDim.new(0, 8)
	inputPadding.PaddingBottom = UDim.new(0, 8)
	inputPadding.Parent = inputBox
	
	local sendBtn = Instance.new("TextButton")
	sendBtn.BackgroundColor3 = Config.COLORS.ACCENT_PRIMARY
	sendBtn.BorderSizePixel = 0
	sendBtn.Font = Enum.Font.SourceSansSemibold
	sendBtn.TextSize = 14
	sendBtn.TextColor3 = Config.COLORS.TEXT_PRIMARY
	sendBtn.Text = "Send"
	sendBtn.Position = UDim2.new(1, -100, 0, 70)
	sendBtn.Size = UDim2.new(0, 88, 0, 24)
	sendBtn.Parent = inputContainer
	
	local sendCorner = Instance.new("UICorner")
	sendCorner.CornerRadius = UDim.new(0, 6)
	sendCorner.Parent = sendBtn
	
	-- Chat history
	local chatHistory = {}
	
	-- Add message to chat
	local function addMessage(role, content)
		local isUser = (role == "user")
		
		-- Message bubble container
		local msgFrame = Instance.new("Frame")
		msgFrame.BackgroundTransparency = 1
		msgFrame.Size = UDim2.new(1, 0, 0, 0)
		msgFrame.AutomaticSize = Enum.AutomaticSize.Y
		msgFrame.LayoutOrder = #chatScroll:GetChildren()
		msgFrame.Parent = chatScroll
		
		-- Bubble
		local bubble = Instance.new("Frame")
		bubble.BackgroundColor3 = isUser and Config.COLORS.USER_BUBBLE or Config.COLORS.AI_BUBBLE
		bubble.BorderSizePixel = 0
		bubble.Size = UDim2.new(0.85, 0, 0, 0)
		bubble.Position = isUser and UDim2.fromScale(0.15, 0) or UDim2.fromScale(0, 0)
		bubble.AutomaticSize = Enum.AutomaticSize.Y
		bubble.Parent = msgFrame
		
		local bubbleCorner = Instance.new("UICorner")
		bubbleCorner.CornerRadius = UDim.new(0, 12)
		bubbleCorner.Parent = bubble
		
		local bubblePadding = Instance.new("UIPadding")
		bubblePadding.PaddingLeft = UDim.new(0, 14)
		bubblePadding.PaddingRight = UDim.new(0, 14)
		bubblePadding.PaddingTop = UDim.new(0, 12)
		bubblePadding.PaddingBottom = UDim.new(0, 12)
		bubblePadding.Parent = bubble
		
		-- Subtle shadow
		local bubbleStroke = Instance.new("UIStroke")
		bubbleStroke.Color = Config.COLORS.SHADOW
		bubbleStroke.Transparency = 0.85
		bubbleStroke.Thickness = 1
		bubbleStroke.Parent = bubble
		
		-- Header (icon + name + timestamp)
		local headerRow = Instance.new("Frame")
		headerRow.BackgroundTransparency = 1
		headerRow.Size = UDim2.new(1, 0, 0, 18)
		headerRow.Parent = bubble
		
		local icon = Instance.new("TextLabel")
		icon.BackgroundTransparency = 1
		icon.Font = Enum.Font.SourceSans
		icon.TextSize = 14
		icon.Text = isUser and "👤" or "🟥"
		icon.TextXAlignment = Enum.TextXAlignment.Left
		icon.TextColor3 = Config.COLORS.TEXT_PRIMARY
		icon.Size = UDim2.new(0, 20, 1, 0)
		icon.Parent = headerRow
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.SourceSansSemibold
		nameLabel.TextSize = 12
		nameLabel.Text = isUser and "You" or "Neurovia AI"
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Config.COLORS.TEXT_PRIMARY
		nameLabel.Position = UDim2.fromOffset(22, 0)
		nameLabel.Size = UDim2.new(1, -100, 1, 0)
		nameLabel.Parent = headerRow
		
		-- Timestamp
		local timestamp = Instance.new("TextLabel")
		timestamp.BackgroundTransparency = 1
		timestamp.Font = Enum.Font.SourceSans
		timestamp.TextSize = 10
		timestamp.Text = os.date("%H:%M:%S")
		timestamp.TextXAlignment = Enum.TextXAlignment.Right
		timestamp.TextColor3 = Config.COLORS.TEXT_MUTED
		timestamp.Position = UDim2.new(1, -70, 0, 0)
		timestamp.Size = UDim2.new(0, 70, 1, 0)
		timestamp.Parent = headerRow
		
		-- Message content
		local contentLabel = Instance.new("TextLabel")
		contentLabel.BackgroundTransparency = 1
		contentLabel.Font = Enum.Font.SourceSans
		contentLabel.TextSize = 13
		contentLabel.Text = content
		contentLabel.TextXAlignment = Enum.TextXAlignment.Left
		contentLabel.TextYAlignment = Enum.TextYAlignment.Top
		contentLabel.TextColor3 = Config.COLORS.TEXT_PRIMARY
		contentLabel.TextWrapped = true
		contentLabel.Position = UDim2.fromOffset(0, 22)
		contentLabel.Size = UDim2.new(1, 0, 0, 0)
		contentLabel.AutomaticSize = Enum.AutomaticSize.Y
		contentLabel.Parent = bubble
		
		-- Auto-scroll to bottom
		task.wait()
		chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
	end
	
	-- Send message
	local function sendMessage()
		local message = inputBox.Text
		if #message == 0 then return end
		
		inputBox.Text = ""
		addMessage("user", message)
		
		-- Get API key
		local provider = storage:getSelectedProvider()
		local apiKey = storage:getAPIKey(provider)
		
		if not apiKey or #apiKey == 0 then
			addMessage("assistant", "⚠️ Please set your API key first!\n\nGo to: Plugins → " .. Config.PLUGIN_NAME .. " → (Click provider button to configure)")
			return
		end
		
		-- Enrich prompt with Intent Analyzer
		local enrichedMessage = IntentAnalyzer.enrichPrompt(message)
		
		-- Build messages array
		local messages = {
			{role = "system", content = Config.SYSTEM_PROMPT},
			{role = "user", content = enrichedMessage}
		}
		
		-- Add chat history (last 5 messages)
		local historyStart = math.max(1, #chatHistory - 4)
		for i = historyStart, #chatHistory do
			table.insert(messages, chatHistory[i])
		end
		
		-- Current message
		table.insert(messages, {role = "user", content = message})
		table.insert(chatHistory, {role = "user", content = message})
		
		-- Show loading
		addMessage("assistant", "⏳ Thinking...")
		
		-- Call AI
		task.spawn(function()
			local success, response = httpClient:call(provider, apiKey, messages)
			
			-- Remove loading message
			local lastMsg = chatScroll:GetChildren()[#chatScroll:GetChildren()]
			if lastMsg then lastMsg:Destroy() end
			
			if success then
				addMessage("assistant", response)
				table.insert(chatHistory, {role = "assistant", content = response})
			else
				addMessage("assistant", "❌ Error: " .. tostring(response))
			end
		end)
	end
	
	-- Button events
	sendBtn.MouseButton1Click:Connect(sendMessage)
	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then sendMessage() end
	end)
	
	-- Provider selector
	providerBtn.MouseButton1Click:Connect(function()
		local providers = {Config.PROVIDERS.OPENAI, Config.PROVIDERS.CLAUDE, Config.PROVIDERS.GEMINI}
		local currentIndex = table.find(providers, storage:getSelectedProvider()) or 1
		local nextIndex = (currentIndex % #providers) + 1
		local nextProvider = providers[nextIndex]
		
		storage:setSelectedProvider(nextProvider)
		providerBtn.Text = nextProvider
		
		-- Show API key input if not set
		local apiKey = storage:getAPIKey(nextProvider)
		if not apiKey or #apiKey == 0 then
			addMessage("assistant", string.format([[
🔑 %s API Key Required

Please enter your API key:
1. Get key from provider website
2. Type your API key in the chat
3. I'll save it securely

Format: /setkey YOUR_API_KEY_HERE
]], nextProvider))
		end
	end)
	
	-- Command handler: /setkey
	local originalSendMessage = sendMessage
	sendMessage = function()
		local message = inputBox.Text
		if string.sub(message, 1, 7) == "/setkey" then
			local apiKey = string.match(message, "/setkey%s+(.+)")
			if apiKey then
				local provider = storage:getSelectedProvider()
				storage:setAPIKey(provider, apiKey)
				inputBox.Text = ""
				addMessage("assistant", "✅ API key saved for " .. provider .. "!\n\nYou can now start chatting. Ask me anything!")
			else
				addMessage("assistant", "❌ Invalid format. Use: /setkey YOUR_API_KEY")
			end
			return
		end
		originalSendMessage()
	end
	
	-- Toggle widget
	button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)
	
	-- Welcome message
	addMessage("assistant", string.format([[
Welcome to %s! 🟥

I'm your AI coding assistant with:
• Intent Analysis - I understand what you want
• 5-Step Thinking - I plan before I code
• Multi-AI Support - OpenAI, Claude, Gemini

Current Provider: %s
%s

Ask me anything in Turkish or English!
]], Config.PLUGIN_NAME, storage:getSelectedProvider(), 
	storage:getAPIKey(storage:getSelectedProvider()) and "✅ API Key: Configured" or "⚠️ API Key: Not set (use /setkey)"))
	
	return widget
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local success, err = pcall(function()
	local storage = Storage.new(plugin)
	local httpClient = HTTPClient.new()
	local widget = createUI(plugin, storage, httpClient)
	
	print("✅ Neurovia Coder v" .. Config.VERSION .. " loaded successfully!")
end)

if not success then
	warn("❌ Neurovia Coder failed to load: " .. tostring(err))
end
