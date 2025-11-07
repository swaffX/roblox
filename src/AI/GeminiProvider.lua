--[[
	GeminiProvider - Google Gemini API Entegrasyonu
]]

local Config = require(script.Parent.Parent.Config)

local GeminiProvider = {}
GeminiProvider.__index = GeminiProvider

function GeminiProvider.new(httpClient, storage)
	local self = setmetatable({}, GeminiProvider)
	self._http = httpClient
	self._storage = storage
	return self
end

function GeminiProvider:chat(messages, model)
	model = model or Config.DEFAULT_MODELS.GEMINI
	local apiKey = self._storage:getAPIKey("GEMINI")
	
	if not apiKey then
		return false, "No Gemini API key configured"
	end
	
	return self._http:callGemini(apiKey, model, messages)
end

function GeminiProvider:validateKey(apiKey)
	if not apiKey or #apiKey < 10 then
		return false
	end
	return string.match(apiKey, "^[A-Za-z0-9_%-]+$") ~= nil
end

return GeminiProvider
