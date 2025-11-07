--[[
	PromptBuilder - AI Prompt Oluşturma Modülü
	
	Workspace context ve user input'u birleştirerek AI için optimize edilmiş prompt'lar oluşturur.
]]

local Config = require(script.Parent.Parent.Config)

local PromptBuilder = {}
PromptBuilder.__index = PromptBuilder

function PromptBuilder.new(codeAnalyzer)
	local self = setmetatable({}, PromptBuilder)
	
	self._analyzer = codeAnalyzer
	
	return self
end

-- AI mesaj dizisi oluştur
function PromptBuilder:buildMessages(userMessage, selectedScript, includeContext)
	includeContext = includeContext == nil and true or includeContext
	
	local messages = {}
	
	-- System prompt
	local systemPrompt = Config.SYSTEM_PROMPTS.DEFAULT
	
	-- Context ekle
	if includeContext and self._analyzer then
		local context = self._analyzer:buildAIContext(game, 10)
		local contextStr = self._analyzer:formatContextForAI(context)
		systemPrompt = systemPrompt .. "\n\n" .. contextStr
	end
	
	-- Selected script varsa ekle
	if selectedScript then
		local source = selectedScript.Source
		systemPrompt = systemPrompt .. string.format(
			"\n\nCurrently selected script: %s\n```lua\n%s\n```",
			selectedScript.Name,
			source
		)
	end
	
	table.insert(messages, {
		role = "system",
		content = systemPrompt
	})
	
	-- User message
	table.insert(messages, {
		role = "user",
		content = userMessage
	})
	
	return messages
end

-- Analysis için özel prompt
function PromptBuilder:buildAnalysisPrompt(parent)
	parent = parent or game
	
	local messages = {}
	
	table.insert(messages, {
		role = "system",
		content = Config.SYSTEM_PROMPTS.ANALYSIS
	})
	
	if self._analyzer then
		local analysis = self._analyzer:analyzeWorkspace(parent)
		local contextStr = string.format(
			"Total scripts: %d\nTotal lines: %d\nTotal functions: %d\nAverage complexity: %.1f",
			analysis.totalScripts,
			analysis.summary.totalLines,
			analysis.summary.totalFunctions,
			analysis.summary.totalComplexity / math.max(1, analysis.totalScripts)
		)
		
		table.insert(messages, {
			role = "user",
			content = "Analyze this Roblox project:\n\n" .. contextStr
		})
	end
	
	return messages
end

-- Refactor için özel prompt
function PromptBuilder:buildRefactorPrompt(scriptInstance)
	if not scriptInstance then
		return nil
	end
	
	local messages = {}
	
	table.insert(messages, {
		role = "system",
		content = Config.SYSTEM_PROMPTS.REFACTOR
	})
	
	local source = scriptInstance.Source
	table.insert(messages, {
		role = "user",
		content = string.format(
			"Refactor this script:\n\nScript: %s\n```lua\n%s\n```",
			scriptInstance.Name,
			source
		)
	})
	
	return messages
end

-- Conversation history ile mesaj oluştur
function PromptBuilder:buildConversationMessages(conversationHistory, newUserMessage)
	local messages = {}
	
	-- System prompt
	table.insert(messages, {
		role = "system",
		content = Config.SYSTEM_PROMPTS.DEFAULT
	})
	
	-- History'yi ekle
	for _, historyItem in ipairs(conversationHistory) do
		table.insert(messages, {
			role = historyItem.role,
			content = historyItem.content
		})
	end
	
	-- Yeni mesaj
	table.insert(messages, {
		role = "user",
		content = newUserMessage
	})
	
	return messages
end

return PromptBuilder
