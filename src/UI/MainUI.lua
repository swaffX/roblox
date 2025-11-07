--[[
	MainUI - Ana UI ve Ekran Düzeni
	
	Vibe Coder tarzında modern, koyu temalı chat + panel yerleşimi
]]

local Config = require(script.Parent.Parent.Config)
local Components = require(script.Parent.Components)
local ResponseParser = require(script.Parent.Parent.AI.ResponseParser)

local MainUI = {}
MainUI.__index = MainUI

function MainUI.new(plugin, apiManager, promptBuilder, codeAnalyzer, workspaceManager, historyManager, localization, logger)
	local self = setmetatable({}, MainUI)
	self._plugin = plugin
	self._api = apiManager
	self._prompt = promptBuilder
	self._analyzer = codeAnalyzer
	self._workspace = workspaceManager
	self._history = historyManager
	self._i18n = localization
	self._logger = logger
	
	return self
end

function MainUI:mount(widget)
	-- Root frame
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = Config.COLORS.BACKGROUND_PRIMARY
	root.BorderSizePixel = 0
	root.Size = UDim2.new(1, 0, 1, 0)
	root.Parent = widget
	
	-- Top Bar
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BackgroundColor3 = Config.COLORS.BACKGROUND_SECONDARY
	topBar.BorderSizePixel = 0
	topBar.Size = UDim2.new(1, 0, 0, 40)
	topBar.Parent = root
	
	local title = Components.Label({
		Parent = topBar,
		Text = self._i18n:get("app.title") .. " • " .. Config.PLUGIN_VERSION,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		TextColor = Config.COLORS.TEXT_PRIMARY,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center
	})
	
	-- Provider dropdown + Settings + Undo/Redo icons
	local rightControls = Instance.new("Frame")
	rightControls.BackgroundTransparency = 1
	rightControls.Size = UDim2.new(0, 300, 1, 0)
	rightControls.Position = UDim2.new(1, -310, 0, 0)
	rightControls.Parent = topBar
	
	local providerDropdown, providerAPI = Components.Dropdown({ Parent = rightControls, DefaultText = "Provider" })
	providerDropdown.Position = UDim2.new(0, 0, 0.5, -18)
	
	for key,_ in pairs(Config.AI_PROVIDERS) do
		providerAPI:AddItem(key, key)
	end
	
	local settingsBtn = Components.IconButton({ Parent = rightControls, Position = UDim2.new(1, -70, 0.5, -16), Icon = "rbxassetid://6031280882" })
	local undoBtn = Components.IconButton({ Parent = rightControls, Position = UDim2.new(1, -36, 0.5, -16), Icon = "rbxassetid://6031097225" })
	
	undoBtn.MouseButton1Click:Connect(function()
		self._history:undo()
	end)
	
	-- Left: History/Files (collapsed simple for now)
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.BackgroundColor3 = Config.COLORS.BACKGROUND_SECONDARY
	leftPanel.BorderSizePixel = 0
	leftPanel.Position = UDim2.new(0, 0, 0, 40)
	leftPanel.Size = UDim2.new(0, 240, 1, -40)
	leftPanel.Parent = root
	
	local leftTitle = Components.Label({ Parent = leftPanel, Text = self._i18n:get("history.title") or "History", TextSize = 12, Font = Enum.Font.GothamBold, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 6), TextColor = Config.COLORS.TEXT_SECONDARY, TextYAlignment = Enum.TextYAlignment.Center })
	Components.Separator({ Parent = leftPanel, Position = UDim2.new(0, 0, 0, 36) })
	
	local historyList = Components.ScrollFrame({ Parent = leftPanel, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 1, -40), Padding = 8 })
	
	-- Right: Main Chat + Preview
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.BackgroundTransparency = 1
	main.Position = UDim2.new(0, 240, 0, 40)
	main.Size = UDim2.new(1, -240, 1, -40)
	main.Parent = root
	
	local chatArea = Components.ScrollFrame({ Parent = main, Name = "ChatArea", BackgroundColor = Config.COLORS.BACKGROUND_SECONDARY, Size = UDim2.new(1, -16, 1, -160), Position = UDim2.new(0, 8, 0, 8), Padding = 10 })
	
	-- Input area
	local inputContainer = Instance.new("Frame")
	inputContainer.Name = "InputContainer"
	inputContainer.BackgroundColor3 = Config.COLORS.BACKGROUND_SECONDARY
	inputContainer.BorderSizePixel = 0
	inputContainer.Size = UDim2.new(1, -16, 0, 140)
	inputContainer.Position = UDim2.new(0, 8, 1, -148)
	inputContainer.Parent = main
	
	local inputBoxContainer, inputBox = Components.MultiLineTextBox({ Parent = inputContainer, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -120, 1, -16), Placeholder = self._i18n:get("chat.placeholder") })
	
	local sendBtn = Components.Button({ Parent = inputContainer, Text = self._i18n:get("button.send"), Position = UDim2.new(1, -100, 1, -44), Size = UDim2.new(0, 92, 0, 36), OnClick = function()
		self:_onSend(inputBox, chatArea, historyList, providerAPI)
	end })
	
	-- Settings modal (lazy shown)
	local settingsModal
	settingsBtn.MouseButton1Click:Connect(function()
		settingsModal = settingsModal or self:_createSettingsModal(root, providerAPI)
		settingsModal.Visible = not settingsModal.Visible
	end)
	
	self._widgets = { root = root, chat = chatArea, history = historyList }
	return root
end

function MainUI:_createSettingsModal(parent, providerAPI)
	local modal = Instance.new("Frame")
	modal.Name = "SettingsModal"
	modal.BackgroundColor3 = Config.COLORS.BACKGROUND_MODAL
	modal.BorderSizePixel = 0
	modal.Size = UDim2.new(0.6, 0, 0.7, 0)
	modal.Position = UDim2.new(0.2, 0, 0.15, 0)
	modal.Visible = false
	modal.ZIndex = 20
	modal.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = modal
	
	local title = Components.Label({ Parent = modal, Text = self._i18n:get("settings.title") or "Settings", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -24, 0, 28) })
	Components.Separator({ Parent = modal, Position = UDim2.new(0, 0, 0, 40) })
	
	local body = Components.ScrollFrame({ Parent = modal, Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 1, -84), Padding = 12 })
	
	-- Provider selection
	Components.Label({ Parent = body, Text = "AI Provider", TextSize = 12, TextColor = Config.COLORS.TEXT_SECONDARY })
	local providerRow = Instance.new("Frame")
	providerRow.BackgroundTransparency = 1
	providerRow.Size = UDim2.new(1, 0, 0, 40)
	providerRow.Parent = body
	
	local dropdown, api = Components.Dropdown({ Parent = providerRow, DefaultText = "Select provider", Size = UDim2.new(0, 220, 0, 36), Position = UDim2.new(0, 0, 0, 2) })
	for key,_ in pairs(Config.AI_PROVIDERS) do api:AddItem(key, key) end
	
	-- API keys
	Components.Label({ Parent = body, Text = "API Keys", TextSize = 12, TextColor = Config.COLORS.TEXT_SECONDARY })
	local openaiBox = Components.TextBox({ Parent = body, Placeholder = "OpenAI API Key (sk-...)" })
	local claudeBox = Components.TextBox({ Parent = body, Placeholder = "Claude API Key (sk-ant-...)" })
	local geminiBox = Components.TextBox({ Parent = body, Placeholder = "Gemini API Key" })
	
	-- Save button
	local saveBtn = Components.Button({ Parent = modal, Text = "Save", Position = UDim2.new(1, -100, 1, -40), Size = UDim2.new(0, 92, 0, 32) })
	saveBtn.MouseButton1Click:Connect(function()
		-- Persist using Storage via apiManager's storage
		local storage = self._api and self._api._storage
		if storage then
			if openaiBox and openaiBox:FindFirstChild("TextBox") then storage:saveAPIKey(Config.AI_PROVIDERS.OPENAI, openaiBox.TextBox.Text) end
			if claudeBox and claudeBox:FindFirstChild("TextBox") then storage:saveAPIKey(Config.AI_PROVIDERS.CLAUDE, claudeBox.TextBox.Text) end
			if geminiBox and geminiBox:FindFirstChild("TextBox") then storage:saveAPIKey(Config.AI_PROVIDERS.GEMINI, geminiBox.TextBox.Text) end
		end
		modal.Visible = false
	end)
	
	return modal
end

function MainUI:_pushHistory(text)
	local item = Components.Label({ Parent = self._widgets.history, Text = text, TextSize = 12, TextColor = Config.COLORS.TEXT_SECONDARY, Size = UDim2.new(1, -16, 0, 20) })
	item.LayoutOrder = os.time()
end

function MainUI:_addMessage(role, content)
	Components.ChatMessage({ Parent = self._widgets.chat, Role = role, Message = content })
end

function MainUI:_addCodePreview(language, code)
	Components.CodeBlock({ Parent = self._widgets.chat, Language = language, Code = code })
end

function MainUI:_onSend(inputBox, chatArea, historyList, providerAPI)
	local message = inputBox.Text
	if #message == 0 then return end
	
	self:_addMessage("user", message)
	self:_pushHistory("You: " .. string.sub(message, 1, 40))
	
	-- Build messages
	local messages = self._prompt:buildMessages(message, nil, true)
	
	-- Loading spinner
	local spinner = Components.LoadingSpinner({ Parent = self._widgets.chat })
	
	task.spawn(function()
		local providerName = providerAPI and providerAPI:GetValue() or nil
		local success, response = self._api:chat(messages, providerName)
		spinner:Destroy()
		
		if success then
			local parsed = ResponseParser.parse(response)
			self:_addMessage("assistant", parsed.explanation)
			if parsed.hasCode then
				for _, block in ipairs(parsed.codeBlocks) do
					self:_addCodePreview(block.language or "lua", block.code)
				end
			end
		else
			self:_addMessage("assistant", "<font color='#FF5555'>" .. tostring(response) .. "</font>")
		end
	end)
	
	inputBox.Text = ""
end

return MainUI
