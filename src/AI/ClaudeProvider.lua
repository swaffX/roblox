--[[
	ClaudeProvider - Claude API Entegrasyonu
]]

local Config = require(script.Parent.Parent.Config)

local ClaudeProvider = {}
ClaudeProvider.__index = ClaudeProvider

function ClaudeProvider.new(httpClient, storage)
	local self = setmetatable({}, ClaudeProvider)
	self._http = httpClient
	self._storage = storage
	return self
end

function ClaudeProvider:chat(messages, model)
	model = model or Config.DEFAULT_MODELS.CLAUDE
	local apiKey = self._storage:getAPIKey("CLAUDE")
	
	if not apiKey then
		return false, "No Claude API key configured"
	end
	
	return self._http:callClaude(apiKey, model, messages)
end

function ClaudeProvider:validateKey(apiKey)
	if not apiKey or #apiKey < 10 then
		return false
	end
	return string.match(apiKey, "^sk%-ant%-") ~= nil
end

return ClaudeProvider
