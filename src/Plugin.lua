--[[
	AI Coder Plugin - Ana Entry Point
	
	Roblox Studio için AI-destekli kodlama asistanı plugin'i
]]

-- Load all modules
local Config = require(script.Config)

-- Utils
local Logger = require(script.Utils.Logger)
local Storage = require(script.Utils.Storage)
local Encryption = require(script.Utils.Encryption)
local Localization = require(script.Utils.Localization)
local HTTPClient = require(script.Utils.HTTPClient)

-- Core
local SecurityManager = require(script.Core.SecurityManager)
local WorkspaceManager = require(script.Core.WorkspaceManager)
local CodeAnalyzer = require(script.Core.CodeAnalyzer)
local DiffEngine = require(script.Core.DiffEngine)
local HistoryManager = require(script.Core.HistoryManager)

-- AI
local PromptBuilder = require(script.AI.PromptBuilder)
local ResponseParser = require(script.AI.ResponseParser)
local APIManager = require(script.AI.APIManager)

-- UI
local Themes = require(script.UI.Themes)

-- Initialize plugin
local toolbar = plugin:CreateToolbar("AI Coder")
local button = toolbar:CreateButton(
	"AI Coder",
	"AI-powered coding assistant",
	"rbxassetid://0" -- Icon
)

-- Initialize core systems
local logger = Logger.new(plugin)
local storage = Storage.new(plugin)
local localization = Localization.new(storage)
local httpClient = HTTPClient.new(logger)

-- Initialize managers
local securityManager = SecurityManager.new(logger)
local workspaceManager = WorkspaceManager.new(logger, securityManager)
local codeAnalyzer = CodeAnalyzer.new(workspaceManager, logger)
local historyManager = HistoryManager.new(workspaceManager, storage, logger)

-- Initialize AI
local promptBuilder = PromptBuilder.new(codeAnalyzer)
local apiManager = APIManager.new(httpClient, storage, logger)

-- Create main UI
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- Initially enabled
	false, -- Override previous enabled
	Config.UI.WINDOW_DEFAULT_WIDTH,
	Config.UI.WINDOW_DEFAULT_HEIGHT,
	Config.UI.WINDOW_MIN_WIDTH,
	Config.UI.WINDOW_MIN_HEIGHT
)

local widget = plugin:CreateDockWidgetPluginGui("AICoderWidget", widgetInfo)
widget.Title = localization:get("app.title")

-- Simple UI (Placeholder - tam UI implementasyonu çok uzun)
local mainFrame = Themes.createFrame(widget, {
	backgroundColor = Config.COLORS.BACKGROUND_PRIMARY
})

local titleLabel = Themes.createLabel(mainFrame, localization:get("app.title"), {
	textSize = 24,
	size = UDim2.new(1, -20, 0, 50)
})
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local descLabel = Themes.createLabel(mainFrame, localization:get("app.description"), {
	textSize = 14,
	textColor = Config.COLORS.TEXT_SECONDARY,
	size = UDim2.new(1, -20, 0, 30)
})
descLabel.Position = UDim2.new(0, 10, 0, 70)
descLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Chat input area
local inputBox = Themes.createTextBox(mainFrame, localization:get("chat.placeholder"), {
	multiline = true
})
inputBox.Size = UDim2.new(1, -20, 0, 100)
inputBox.Position = UDim2.new(0, 10, 1, -150)

-- Send button
local sendButton = Themes.createButton(mainFrame, localization:get("button.send"), function()
	local message = inputBox.Text
	if #message == 0 then
		return
	end
	
	-- Build prompt
	local messages = promptBuilder:buildMessages(message, nil, true)
	
	-- Send to AI
	task.spawn(function()
		local success, response = apiManager:chat(messages)
		
		if success then
			logger:info("AI Response received", { length = #response })
			-- Parse response
			local parsed = ResponseParser.parse(response)
			
			if parsed.hasCode and #parsed.codeBlocks > 0 then
				-- Show preview for code changes
				for _, block in ipairs(parsed.codeBlocks) do
					logger:info("Code block found", { lines = select(2, string.gsub(block.code, "\n", "\n")) })
				end
			end
		else
			warn("AI Error:", response)
		end
	end)
	
	inputBox.Text = ""
end)
sendButton.Size = UDim2.new(0, 100, 0, 35)
sendButton.Position = UDim2.new(1, -110, 1, -40)

-- Settings button
local settingsButton = Themes.createButton(mainFrame, localization:get("button.settings"), function()
	-- Open settings (placeholder)
	logger:info("Settings clicked")
end)
settingsButton.Size = UDim2.new(0, 100, 0, 35)
settingsButton.Position = UDim2.new(0, 10, 1, -40)
settingsButton.BackgroundColor3 = Config.COLORS.SURFACE_ELEVATED

-- Toolbar button click
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Log initialization
logger:info("AI Coder Plugin initialized", {
	version = Config.PLUGIN_VERSION
})

print("AI Coder Plugin loaded successfully!")
