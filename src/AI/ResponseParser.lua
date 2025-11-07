--[[
	ResponseParser - AI Response Ayrıştırıcı
	
	AI'dan gelen yanıtları parse eder, kod bloklarını çıkarır,
	metadata'yı işler ve kullanılabilir formata çevirir.
]]

local ResponseParser = {}

-- Kod bloklarını çıkar
local function extractCodeBlocks(text)
	local codeBlocks = {}
	
	-- ```lua ... ``` pattern'i bul
	for codeBlock in string.gmatch(text, "```lua\n(.-)\n```") do
		table.insert(codeBlocks, {
			language = "lua",
			code = codeBlock
		})
	end
	
	-- ```luau ... ``` pattern'i bul
	for codeBlock in string.gmatch(text, "```luau\n(.-)\n```") do
		table.insert(codeBlocks, {
			language = "luau",
			code = codeBlock
		})
	end
	
	-- Generic ``` ... ``` (language belirtilmemiş)
	if #codeBlocks == 0 then
		for codeBlock in string.gmatch(text, "```\n(.-)\n```") do
			table.insert(codeBlocks, {
				language = "unknown",
				code = codeBlock
			})
		end
	end
	
	return codeBlocks
end

-- Script path'i extract et
local function extractScriptPath(text)
	-- "Script: Path.To.Script" veya "path: Path.To.Script" pattern'i
	local path = string.match(text, "[Ss]cript:%s*([%w%.]+)")
	if path then
		return path
	end
	
	-- "in ServerScriptService.MainScript" pattern'i
	path = string.match(text, "in%s+([%w%.]+)")
	if path then
		return path
	end
	
	return nil
end

-- Operation tipini detect et
local function detectOperation(text)
	local lowerText = string.lower(text)
	
	if string.match(lowerText, "creat") or string.match(lowerText, "new script") then
		return "create"
	elseif string.match(lowerText, "delet") or string.match(lowerText, "remov") then
		return "delete"
	elseif string.match(lowerText, "updat") or string.match(lowerText, "modif") or string.match(lowerText, "chang") then
		return "update"
	elseif string.match(lowerText, "refactor") then
		return "refactor"
	end
	
	return "unknown"
end

-- Explanation çıkar (kod bloklarından önceki/sonraki açıklama)
local function extractExplanation(text)
	-- İlk kod bloğundan önceki text
	local beforeCode = string.match(text, "^(.-)```")
	if beforeCode then
		-- Trim whitespace
		beforeCode = string.gsub(beforeCode, "^%s+", "")
		beforeCode = string.gsub(beforeCode, "%s+$", "")
		return beforeCode
	end
	
	return text
end

-- Ana parse fonksiyonu
function ResponseParser.parse(responseText)
	if not responseText or #responseText == 0 then
		return {
			hasCode = false,
			codeBlocks = {},
			operation = "none",
			explanation = "",
			scriptPath = nil
		}
	end
	
	local codeBlocks = extractCodeBlocks(responseText)
	local operation = detectOperation(responseText)
	local scriptPath = extractScriptPath(responseText)
	local explanation = extractExplanation(responseText)
	
	return {
		hasCode = #codeBlocks > 0,
		codeBlocks = codeBlocks,
		operation = operation,
		explanation = explanation,
		scriptPath = scriptPath,
		rawResponse = responseText
	}
end

-- Markdown formatını temizle
function ResponseParser.stripMarkdown(text)
	-- Code blocks
	text = string.gsub(text, "```.-```", "")
	
	-- Bold
	text = string.gsub(text, "%*%*(.-)%*%*", "%1")
	
	-- Italic
	text = string.gsub(text, "%*(.-)%*", "%1")
	
	-- Headers
	text = string.gsub(text, "#+%s*", "")
	
	-- Links
	text = string.gsub(text, "%[(.-)%]%((.-)%)", "%1")
	
	return text
end

-- Code block'tan script bilgilerini çıkar
function ResponseParser.parseCodeBlock(codeBlock)
	local lines = {}
	for line in string.gmatch(codeBlock.code, "[^\n]+") do
		table.insert(lines, line)
	end
	
	-- İlk satırda comment varsa script bilgisi olabilir
	local firstLine = lines[1]
	local scriptInfo = {
		name = nil,
		type = "Script",
		path = nil
	}
	
	if firstLine and string.match(firstLine, "^%-%-") then
		-- "-- Script: Name" pattern
		local name = string.match(firstLine, "%-%-.-Script:%s*([%w_]+)")
		if name then
			scriptInfo.name = name
		end
		
		-- "-- Type: LocalScript" pattern
		local scriptType = string.match(firstLine, "%-%-.-Type:%s*(%w+)")
		if scriptType then
			scriptInfo.type = scriptType
		end
		
		-- "-- Path: ServerScriptService.MainScript" pattern
		local path = string.match(firstLine, "%-%-.-Path:%s*([%w%.]+)")
		if path then
			scriptInfo.path = path
		end
	end
	
	return scriptInfo
end

-- Provider-specific response format'ını normalize et
function ResponseParser.normalizeProviderResponse(provider, rawResponse)
	-- OpenAI format
	if provider == "OPENAI" then
		if type(rawResponse) == "table" and rawResponse.choices then
			return rawResponse.choices[1].message.content
		end
	end
	
	-- Claude format
	if provider == "CLAUDE" then
		if type(rawResponse) == "table" and rawResponse.content then
			if type(rawResponse.content) == "table" then
				return rawResponse.content[1].text
			end
			return rawResponse.content
		end
	end
	
	-- Gemini format
	if provider == "GEMINI" then
		if type(rawResponse) == "table" and rawResponse.candidates then
			return rawResponse.candidates[1].content.parts[1].text
		end
	end
	
	-- Fallback: string olarak dön
	if type(rawResponse) == "string" then
		return rawResponse
	end
	
	return ""
end

return ResponseParser
