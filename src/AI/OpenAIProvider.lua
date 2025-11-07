--[[
	OpenAIProvider - OpenAI API Entegrasyonu
]]

local Config = require(script.Parent.Parent.Config)

local OpenAIProvider = {}
OpenAIProvider.__index = OpenAIProvider

function OpenAIProvider.new(httpClient, storage)
	local self = setmetatable({}, OpenAIProvider)
	self._http = httpClient
	self._storage = storage
	return self
end

function OpenAIProvider:chat(messages, model)
	model = model or Config.DEFAULT_MODELS.OPENAI
	local apiKey = self._storage:getAPIKey("OPENAI")
	
	if not apiKey then
		return false, "No OpenAI API key configured"
	end
	
	return self._http:callOpenAI(apiKey, model, messages)
end

function OpenAIProvider:validateKey(apiKey)
	if not apiKey or #apiKey < 10 then
		return false
	end
	return string.match(apiKey, "^sk%-") ~= nil
end

return OpenAIProvider
