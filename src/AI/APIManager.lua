--[[
	APIManager - Tüm AI Provider'ları Yöneten Merkezi Modül
]]

local Config = require(script.Parent.Parent.Config)
local OpenAIProvider = require(script.Parent.OpenAIProvider)
local ClaudeProvider = require(script.Parent.ClaudeProvider)
local GeminiProvider = require(script.Parent.GeminiProvider)

local APIManager = {}
APIManager.__index = APIManager

function APIManager.new(httpClient, storage, logger)
	local self = setmetatable({}, APIManager)
	
	self._http = httpClient
	self._storage = storage
	self._logger = logger
	
	self._providers = {
		OPENAI = OpenAIProvider.new(httpClient, storage),
		CLAUDE = ClaudeProvider.new(httpClient, storage),
		GEMINI = GeminiProvider.new(httpClient, storage)
	}
	
	return self
end

function APIManager:getProvider(providerName)
	return self._providers[providerName]
end

function APIManager:chat(messages, providerName, model)
	providerName = providerName or self._storage:getSelectedProvider()
	
	local provider = self:getProvider(providerName)
	if not provider then
		return false, "Invalid provider: " .. tostring(providerName)
	end
	
	if self._logger then
		self._logger:info("AI chat request", {
			provider = providerName,
			messageCount = #messages
		})
	end
	
	local success, response = provider:chat(messages, model)
	
	if self._logger then
		if success then
			self._logger:info("AI chat success", { provider = providerName })
		else
			self._logger:error("AI chat failed", {
				provider = providerName,
				error = response
			})
		end
	end
	
	return success, response
end

function APIManager:validateAPIKey(providerName, apiKey)
	local provider = self:getProvider(providerName)
	if not provider then
		return false
	end
	return provider:validateKey(apiKey)
end

function APIManager:hasValidAPIKey(providerName)
	return self._storage:hasAPIKey(providerName)
end

return APIManager
