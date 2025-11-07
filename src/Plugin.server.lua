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
local MainUI = require(script.UI.MainUI)

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

-- Mount modern UI
local mainUI = MainUI.new(
	plugin,
	apiManager,
	promptBuilder,
	codeAnalyzer,
	workspaceManager,
	historyManager,
	localization,
	logger
)

mainUI:mount(widget)

-- Toolbar button click
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Log initialization
logger:info("AI Coder Plugin initialized", {
	version = Config.PLUGIN_VERSION
})

print("AI Coder Plugin loaded successfully!")
