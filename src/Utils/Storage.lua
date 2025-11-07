--[[
	Storage - Persistent Data Storage
	
	Wraps PluginSettings API to provide secure storage for
	plugin configuration and sensitive data like API keys.
]]

local Encryption = require(script.Parent.Encryption)
local Config = require(script.Parent.Parent.Config)

local Storage = {}
Storage.__index = Storage

-- Create new storage instance
function Storage.new(plugin)
	local self = setmetatable({}, Storage)
	
	self._plugin = plugin
	self._settings = plugin:GetSetting("AICoderSettings") or {}
	
	return self
end

-- Save settings
function Storage:_saveSettings()
	self._plugin:SetSetting("AICoderSettings", self._settings)
end

-- Get value
function Storage:get(key, default)
	local value = self._settings[key]
	
	if value == nil then
		return default
	end
	
	return value
end

-- Set value
function Storage:set(key, value)
	self._settings[key] = value
	self:_saveSettings()
end

-- Check if key exists
function Storage:has(key)
	return self._settings[key] ~= nil
end

-- Remove value
function Storage:remove(key)
	self._settings[key] = nil
	self:_saveSettings()
end

-- Clear all data
function Storage:clear()
	self._settings = {}
	self:_saveSettings()
end

-- Get all keys
function Storage:keys()
	local keys = {}
	for key in pairs(self._settings) do
		table.insert(keys, key)
	end
	return keys
end

-- Secure Methods (for sensitive data like API keys)

-- Get encrypted value
function Storage:getSecure(key, default)
	local encrypted = self:get(key)
	
	if not encrypted then
		return default
	end
	
	local decrypted = Encryption.decrypt(encrypted)
	
	if #decrypted == 0 then
		return default
	end
	
	return decrypted
end

-- Set encrypted value
function Storage:setSecure(key, value)
	if not value or #value == 0 then
		self:remove(key)
		return
	end
	
	local encrypted = Encryption.encrypt(value)
	self:set(key, encrypted)
end

-- Validate API key format
local function isValidAPIKey(provider, key)
	if not key or #key == 0 then
		return false
	end
	
	-- Basic validation
	if #key < 10 then
		return false
	end
	
	-- Provider-specific validation
	if provider == Config.AI_PROVIDERS.OPENAI then
		return string.match(key, "^sk%-")
	elseif provider == Config.AI_PROVIDERS.CLAUDE then
		return string.match(key, "^sk%-ant%-")
	elseif provider == Config.AI_PROVIDERS.GEMINI then
		return string.match(key, "^[A-Za-z0-9_%-]+$")
	end
	
	return true
end

-- API Key Management

-- Get API key for provider
function Storage:getAPIKey(provider)
	local keyName = Config.STORAGE_KEYS["API_KEY_" .. string.upper(provider)]
	return self:getSecure(keyName)
end

-- Set API key for provider
function Storage:setAPIKey(provider, key)
	if not isValidAPIKey(provider, key) then
		return false, "Invalid API key format for " .. provider
	end
	
	local keyName = Config.STORAGE_KEYS["API_KEY_" .. string.upper(provider)]
	self:setSecure(keyName, key)
	return true
end

-- Alias for compatibility
Storage.saveAPIKey = Storage.setAPIKey

-- Remove API key for provider
function Storage:removeAPIKey(provider)
	local keyName = Config.STORAGE_KEYS["API_KEY_" .. string.upper(provider)]
	self:remove(keyName)
end

-- Check if API key exists for provider
function Storage:hasAPIKey(provider)
	local key = self:getAPIKey(provider)
	return key ~= nil and #key > 0
end

-- Configuration Management

-- Get selected AI provider
function Storage:getSelectedProvider()
	return self:get(
		Config.STORAGE_KEYS.SELECTED_PROVIDER,
		Config.AI_PROVIDERS.OPENAI
	)
end

-- Set selected AI provider
function Storage:setSelectedProvider(provider)
	self:set(Config.STORAGE_KEYS.SELECTED_PROVIDER, provider)
end

-- Get selected model for provider
function Storage:getSelectedModel(provider)
	local key = Config.STORAGE_KEYS.SELECTED_MODEL .. "_" .. provider
	return self:get(key, Config.DEFAULT_MODELS[provider])
end

-- Set selected model for provider
function Storage:setSelectedModel(provider, model)
	local key = Config.STORAGE_KEYS.SELECTED_MODEL .. "_" .. provider
	self:set(key, model)
end

-- Get language preference
function Storage:getLanguage()
	return self:get(
		Config.STORAGE_KEYS.LANGUAGE,
		Config.DEFAULT_LANGUAGE
	)
end

-- Set language preference
function Storage:setLanguage(lang)
	self:set(Config.STORAGE_KEYS.LANGUAGE, lang)
end

-- Chat History Management

-- Get chat history
function Storage:getChatHistory()
	local history = self:get(Config.STORAGE_KEYS.CHAT_HISTORY, {})
	return history
end

-- Save chat history
function Storage:saveChatHistory(history)
	-- Limit history size
	if #history > Config.UI.MAX_CHAT_HISTORY then
		local trimmed = {}
		local start = #history - Config.UI.MAX_CHAT_HISTORY + 1
		for i = start, #history do
			table.insert(trimmed, history[i])
		end
		history = trimmed
	end
	
	self:set(Config.STORAGE_KEYS.CHAT_HISTORY, history)
end

-- Clear chat history
function Storage:clearChatHistory()
	self:remove(Config.STORAGE_KEYS.CHAT_HISTORY)
end

-- Operation History Management

-- Get operation history
function Storage:getOperationHistory()
	return self:get(Config.STORAGE_KEYS.OPERATION_HISTORY, {})
end

-- Save operation history
function Storage:saveOperationHistory(history)
	-- Limit history size
	if #history > Config.UI.MAX_HISTORY_ITEMS then
		local trimmed = {}
		local start = #history - Config.UI.MAX_HISTORY_ITEMS + 1
		for i = start, #history do
			table.insert(trimmed, history[i])
		end
		history = trimmed
	end
	
	self:set(Config.STORAGE_KEYS.OPERATION_HISTORY, history)
end

-- Clear operation history
function Storage:clearOperationHistory()
	self:remove(Config.STORAGE_KEYS.OPERATION_HISTORY)
end

-- Window State Management

-- Get window size
function Storage:getWindowSize()
	return self:get(Config.STORAGE_KEYS.WINDOW_SIZE)
end

-- Set window size
function Storage:setWindowSize(width, height)
	self:set(Config.STORAGE_KEYS.WINDOW_SIZE, {
		width = width,
		height = height
	})
end

-- Export all settings (for backup)
function Storage:export()
	local exported = {}
	
	for key, value in pairs(self._settings) do
		-- Don't export encrypted data
		if not string.match(key, "api_key") then
			exported[key] = value
		end
	end
	
	return game:GetService("HttpService"):JSONEncode(exported)
end

-- Import settings (from backup)
function Storage:import(jsonData)
	local success, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(jsonData)
	end)
	
	if not success then
		return false, "Invalid JSON data"
	end
	
	for key, value in pairs(decoded) do
		self._settings[key] = value
	end
	
	self:_saveSettings()
	return true
end

return Storage
