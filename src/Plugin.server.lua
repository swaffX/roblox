--[[
	AI Coder Plugin - Ana Entry Point
	
	Roblox Studio için AI-destekli kodlama asistanı plugin'i
]]

-- Safe module loader
local function safeRequire(module, name)
	local success, result = pcall(function()
		return require(module)
	end)
	if not success then
		warn(string.format("[Neurovia Coder] Failed to load %s: %s", name, tostring(result)))
		return nil
	end
	return result
end

-- Load all modules
local Config = safeRequire(script.Config, "Config")
if not Config then
	warn("[Neurovia Coder] Critical: Config module failed to load. Plugin disabled.")
	return
end

-- Utils
local Logger = safeRequire(script.Utils.Logger, "Logger")
local Storage = safeRequire(script.Utils.Storage, "Storage")
local Encryption = safeRequire(script.Utils.Encryption, "Encryption")
local Localization = safeRequire(script.Utils.Localization, "Localization")
local HTTPClient = safeRequire(script.Utils.HTTPClient, "HTTPClient")

-- Core
local SecurityManager = safeRequire(script.Core.SecurityManager, "SecurityManager")
local WorkspaceManager = safeRequire(script.Core.WorkspaceManager, "WorkspaceManager")
local CodeAnalyzer = safeRequire(script.Core.CodeAnalyzer, "CodeAnalyzer")
local DiffEngine = safeRequire(script.Core.DiffEngine, "DiffEngine")
local HistoryManager = safeRequire(script.Core.HistoryManager, "HistoryManager")

-- AI
local PromptBuilder = safeRequire(script.AI.PromptBuilder, "PromptBuilder")
local ResponseParser = safeRequire(script.AI.ResponseParser, "ResponseParser")
local APIManager = safeRequire(script.AI.APIManager, "APIManager")

-- UI
local Themes = safeRequire(script.UI.Themes, "Themes")
local MainUI = safeRequire(script.UI.MainUI, "MainUI")

-- Check if critical modules loaded
if not (Logger and Storage and MainUI and APIManager) then
	warn("[Neurovia Coder] Critical modules failed to load. Plugin disabled.")
	return
end

-- Safe initialization
local success, err = pcall(function()
	-- Initialize plugin
	local toolbar = plugin:CreateToolbar("Neurovia Coder")
	local button = toolbar:CreateButton(
		"Neurovia Coder",
		"AI-powered coding assistant",
		"rbxassetid://0" -- Icon
	)
	
	-- Initialize core systems
	local logger = Logger.new(plugin)
	local storage = Storage.new(plugin)
	local localization = Localization and Localization.new(storage) or nil
	local httpClient = HTTPClient.new(logger)
	
	-- Initialize managers (with nil checks)
	local securityManager = SecurityManager and SecurityManager.new(logger) or nil
	local workspaceManager = WorkspaceManager and WorkspaceManager.new(logger, securityManager) or nil
	local codeAnalyzer = CodeAnalyzer and workspaceManager and CodeAnalyzer.new(workspaceManager, logger) or nil
	local historyManager = HistoryManager and workspaceManager and HistoryManager.new(workspaceManager, storage, logger) or nil
	
	-- Initialize AI
	local promptBuilder = PromptBuilder and codeAnalyzer and PromptBuilder.new(codeAnalyzer) or nil
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
	
	local widget = plugin:CreateDockWidgetPluginGui("NeuroViaCoderWidget", widgetInfo)
	widget.Title = (localization and localization:get("app.title")) or "Neurovia Coder"
	
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
	logger:info("Neurovia Coder Plugin initialized", {
		version = Config.PLUGIN_VERSION
	})
	
	print("✅ Neurovia Coder loaded successfully!")
end)

if not success then
	warn(string.format("[Neurovia Coder] Plugin initialization failed: %s", tostring(err)))
	print("❌ Neurovia Coder failed to load. Check Output for details.")
end
