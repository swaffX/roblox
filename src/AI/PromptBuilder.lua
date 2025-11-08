--[[
	PromptBuilder - AI Prompt Oluşturma Modülü
	
	Workspace context ve user input'u birleştirerek AI için optimize edilmiş prompt'lar oluşturur.
]]

local Config = require(script.Parent.Parent.Config)
local IntentAnalyzer = require(script.Parent.IntentAnalyzer)

local PromptBuilder = {}
PromptBuilder.__index = PromptBuilder

function PromptBuilder.new(codeAnalyzer)
	local self = setmetatable({}, PromptBuilder)
	
	self._analyzer = codeAnalyzer
	self._intentAnalyzer = IntentAnalyzer.new()
	
	return self
end

-- AI mesaj dizisi oluştur (standart context)
function PromptBuilder:buildMessages(userMessage, selectedScript, includeContext)
	includeContext = includeContext == nil and true or includeContext
	
	local messages = {}
	
	-- System prompt
	local systemPrompt = Config.SYSTEM_PROMPTS.DEFAULT
	
	-- Extended context ekle
	if includeContext and self._analyzer then
		local context = self._analyzer:buildExtendedAIContext(game, 20)
		local contextStr = self._analyzer:formatExtendedContextForAI(context)
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
	
	-- Analyze user intent and enrich the message
	local intentAnalysis = self._intentAnalyzer:analyze(userMessage)
	local enrichedMessage = intentAnalysis.enrichedPrompt
	
	-- User message with intent analysis
	table.insert(messages, {
		role = "user",
		content = enrichedMessage
	})
	
	return messages
end

-- Genişletilmiş context ile mesaj oluştur
function PromptBuilder:buildMessagesWithExtendedContext(userMessage, selectedScript, contextLevel)
	contextLevel = contextLevel or 2 -- 1=minimal, 2=normal, 3=extensive
	
	local messages = {}
	local maxScripts = 10
	
	if contextLevel == 2 then
		maxScripts = 20
	elseif contextLevel == 3 then
		maxScripts = 40
	end
	
	-- System prompt
	local systemPrompt = Config.SYSTEM_PROMPTS.DEFAULT
	
	-- Extended context ekle
	if self._analyzer then
		local context = self._analyzer:buildExtendedAIContext(game, maxScripts)
		local contextStr = self._analyzer:formatExtendedContextForAI(context)
		systemPrompt = systemPrompt .. "\n\n" .. contextStr
	end
	
	-- Selected script varsa ekle
	if selectedScript then
		local source = selectedScript.Source
		systemPrompt = systemPrompt .. string.format(
			"\n\nCurrently selected script: %s (Type: %s)\n```lua\n%s\n```",
			selectedScript.Name,
			selectedScript.ClassName,
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
