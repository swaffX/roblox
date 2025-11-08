--[[
	IntentAnalyzer - Kullanıcı Niyeti Analiz Modülü
	
	Kullanıcının girdiği prompt'u analiz ederek gerçek niyeti belirler
	ve AI'ye daha iyi context sağlar.
]]

local IntentAnalyzer = {}
IntentAnalyzer.__index = IntentAnalyzer

-- Intent türleri
local INTENT_TYPES = {
	CREATE = "create",           -- Yeni bir şey oluştur
	MODIFY = "modify",          -- Var olanı değiştir
	DEBUG = "debug",            -- Hata bul/düzelt
	EXPLAIN = "explain",        -- Açıkla/öğret
	ANALYZE = "analyze",        -- Analiz et
	REFACTOR = "refactor",      -- Yeniden yapılandır
	OPTIMIZE = "optimize",      -- Performans iyileştir
	QUESTION = "question"       -- Soru sor
}

-- Keyword patterns for intent detection
local INTENT_PATTERNS = {
	[INTENT_TYPES.CREATE] = {
		"oluştur", "yap", "ekle", "create", "make", "add", "build", "new",
		"generate", "implement", "write", "code"
	},
	[INTENT_TYPES.MODIFY] = {
		"değiştir", "güncelle", "düzenle", "change", "update", "modify", "edit",
		"alter", "adjust", "fix", "repair"
	},
	[INTENT_TYPES.DEBUG] = {
		"hata", "bug", "çalışmıyor", "error", "doesn't work", "broken", "issue",
		"problem", "crash", "fix", "debug", "troubleshoot"
	},
	[INTENT_TYPES.EXPLAIN] = {
		"açıkla", "nasıl", "ne", "explain", "how", "what", "why", "teach",
		"show me", "tell me", "help me understand"
	},
	[INTENT_TYPES.ANALYZE] = {
		"analiz", "incele", "kontrol", "analyze", "check", "review", "inspect",
		"examine", "evaluate", "assess"
	},
	[INTENT_TYPES.REFACTOR] = {
		"refactor", "reorganize", "restructure", "clean up", "improve structure",
		"yeniden düzenle", "temizle"
	},
	[INTENT_TYPES.OPTIMIZE] = {
		"optimize", "improve", "faster", "better", "performance", "efficient",
		"hızlandır", "iyileştir", "optimize et"
	},
	[INTENT_TYPES.QUESTION] = {
		"?", "mı", "mi", "mu", "mü", "can", "could", "would", "should",
		"is it", "does it", "will it"
	}
}

-- Target types (what user wants to work with)
local TARGET_TYPES = {
	SCRIPT = "script",
	GUI = "gui",
	PART = "part",
	MODEL = "model",
	SYSTEM = "system",
	TOOL = "tool",
	GAME = "game",
	PLAYER = "player",
	ANIMATION = "animation",
	SOUND = "sound"
}

local TARGET_PATTERNS = {
	[TARGET_TYPES.SCRIPT] = {
		"script", "kod", "code", "function", "fonksiyon"
	},
	[TARGET_TYPES.GUI] = {
		"gui", "ui", "button", "frame", "text", "menu", "interface",
		"arayüz", "buton", "ekran"
	},
	[TARGET_TYPES.PART] = {
		"part", "parça", "object", "obje"
	},
	[TARGET_TYPES.MODEL] = {
		"model", "character", "karakter", "npc"
	},
	[TARGET_TYPES.SYSTEM] = {
		"system", "sistem", "manager", "yönetici", "handler"
	},
	[TARGET_TYPES.TOOL] = {
		"tool", "araç", "weapon", "silah", "item", "eşya"
	},
	[TARGET_TYPES.GAME] = {
		"game", "oyun", "level", "seviye", "world", "dünya"
	},
	[TARGET_TYPES.PLAYER] = {
		"player", "oyuncu", "character", "avatar"
	},
	[TARGET_TYPES.ANIMATION] = {
		"animation", "animasyon", "tween", "move", "hareket"
	},
	[TARGET_TYPES.SOUND] = {
		"sound", "ses", "music", "müzik", "audio"
	}
}

function IntentAnalyzer.new()
	local self = setmetatable({}, IntentAnalyzer)
	return self
end

-- Analyze user message and extract intent
function IntentAnalyzer:analyze(userMessage)
	local lowerMessage = string.lower(userMessage)
	
	local result = {
		originalMessage = userMessage,
		intent = nil,
		target = nil,
		confidence = 0,
		keywords = {},
		context = {},
		enrichedPrompt = ""
	}
	
	-- Detect intent
	local intentScores = {}
	for intent, keywords in pairs(INTENT_PATTERNS) do
		local score = 0
		for _, keyword in ipairs(keywords) do
			if string.find(lowerMessage, keyword, 1, true) then
				score = score + 1
				table.insert(result.keywords, keyword)
			end
		end
		if score > 0 then
			intentScores[intent] = score
		end
	end
	
	-- Find highest scoring intent
	local maxScore = 0
	for intent, score in pairs(intentScores) do
		if score > maxScore then
			maxScore = score
			result.intent = intent
		end
	end
	
	-- Detect target type
	local targetScores = {}
	for targetType, keywords in pairs(TARGET_PATTERNS) do
		local score = 0
		for _, keyword in ipairs(keywords) do
			if string.find(lowerMessage, keyword, 1, true) then
				score = score + 1
			end
		end
		if score > 0 then
			targetScores[targetType] = score
		end
	end
	
	-- Find highest scoring target
	local maxTargetScore = 0
	for targetType, score in pairs(targetScores) do
		if score > maxTargetScore then
			maxTargetScore = score
			result.target = targetType
		end
	end
	
	-- Calculate confidence
	result.confidence = math.min(1.0, (maxScore + maxTargetScore) / 5)
	
	-- Build enriched prompt with explicit instructions for AI
	result.enrichedPrompt = self:buildEnrichedPrompt(result, userMessage)
	
	return result
end

-- Build enriched prompt for better AI understanding
function IntentAnalyzer:buildEnrichedPrompt(analysis, originalMessage)
	local prompt = "USER REQUEST ANALYSIS:\n\n"
	
	-- Add detected intent
	if analysis.intent then
		prompt = prompt .. string.format("Detected Intent: %s\n", analysis.intent:upper())
		
		-- Add intent-specific instructions
		if analysis.intent == INTENT_TYPES.CREATE then
			prompt = prompt .. "→ User wants to CREATE something new. Generate complete, ready-to-use code.\n"
		elseif analysis.intent == INTENT_TYPES.MODIFY then
			prompt = prompt .. "→ User wants to MODIFY existing code. Focus on changes only.\n"
		elseif analysis.intent == INTENT_TYPES.DEBUG then
			prompt = prompt .. "→ User needs help DEBUGGING. Identify issues and provide fixes.\n"
		elseif analysis.intent == INTENT_TYPES.EXPLAIN then
			prompt = prompt .. "→ User wants an EXPLANATION. Be educational and clear.\n"
		elseif analysis.intent == INTENT_TYPES.ANALYZE then
			prompt = prompt .. "→ User wants ANALYSIS. Review code and provide insights.\n"
		elseif analysis.intent == INTENT_TYPES.REFACTOR then
			prompt = prompt .. "→ User wants REFACTORING. Improve code structure and quality.\n"
		elseif analysis.intent == INTENT_TYPES.OPTIMIZE then
			prompt = prompt .. "→ User wants OPTIMIZATION. Focus on performance improvements.\n"
		end
	end
	
	-- Add detected target
	if analysis.target then
		prompt = prompt .. string.format("Target Type: %s\n", analysis.target:upper())
		prompt = prompt .. string.format("→ Focus on %s-related solutions.\n", analysis.target)
	end
	
	-- Add confidence
	prompt = prompt .. string.format("Confidence: %.0f%%\n\n", analysis.confidence * 100)
	
	-- Add original message
	prompt = prompt .. "Original User Request:\n" .. originalMessage .. "\n\n"
	
	-- Add thinking instructions
	prompt = prompt .. [[
INSTRUCTIONS FOR AI:
1. Use the 5-step thinking process defined in your system prompt
2. Consider the detected intent and target type above
3. Provide a solution that matches the user's actual goal
4. If confidence is low, ask clarifying questions
5. Always explain your reasoning

Now, process this request using your thinking framework.
]]
	
	return prompt
end

-- Extract potential script names from message
function IntentAnalyzer:extractScriptNames(message)
	local names = {}
	
	-- Look for quoted names
	for name in string.gmatch(message, [["([^"]+)"]]) do
		table.insert(names, name)
	end
	
	-- Look for CamelCase names
	for name in string.gmatch(message, "([A-Z][a-zA-Z]+[A-Z][a-zA-Z]+)") do
		table.insert(names, name)
	end
	
	return names
end

return IntentAnalyzer
