--[[
	ResponseParser - AI Response Ayrıştırıcı
	
	AI'dan gelen yanıtları parse eder, kod bloklarını çıkarır,
	metadata'yı işler ve kullanılabilir formata çevirir.
]]

local ResponseParser = {}

-- Kod bloklarını çıkar (Duplikasyon kontrolü ile)
local function extractCodeBlocks(text)
	local codeBlocks = {}
	local seenCodes = {} -- Duplikasyon kontrol için
	
	-- Helper function: kod hash'ini oluştur (duplikasyon tespit)
	local function getCodeHash(code)
		-- Whitespace'i normalize et ve hash oluştur
		local normalized = string.gsub(code, "%s+", " ")
		normalized = string.gsub(normalized, "^%s+", "")
		normalized = string.gsub(normalized, "%s+$", "")
		return normalized
	end
	
	-- Helper function: kod bloğu ekle (duplikasyon kontrolü ile)
	local function addCodeBlock(language, code)
		if not code or #code == 0 then
			return
		end
		
		local codeHash = getCodeHash(code)
		
		-- Aynı kod zaten varsa ekleme
		if seenCodes[codeHash] then
			return
		end
		
		seenCodes[codeHash] = true
		table.insert(codeBlocks, {
			language = language or "lua",
			code = code,
			hash = codeHash
		})
	end
	
	-- ```lua ... ``` pattern'i bul
	for codeBlock in string.gmatch(text, "```lua\n(.-)\n```") do
		addCodeBlock("lua", codeBlock)
	end
	
	-- ```luau ... ``` pattern'i bul
	for codeBlock in string.gmatch(text, "```luau\n(.-)\n```") do
		addCodeBlock("luau", codeBlock)
	end
	
	-- ```Lua ... ``` (büyük harf)
	for codeBlock in string.gmatch(text, "```Lua\n(.-)\n```") do
		addCodeBlock("lua", codeBlock)
	end
	
	-- Generic ``` ... ``` (language belirtilmemiş)
	for codeBlock in string.gmatch(text, "```\n(.-)\n```") do
		addCodeBlock("lua", codeBlock)
	end
	
	-- Alternatif format: ```lua ... ``` (whitespace tolerant)
	for codeBlock in string.gmatch(text, "```%s*lua%s*(.-)\n```") do
		addCodeBlock("lua", codeBlock)
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

-- Operation tipini detect et (genişletilmiş)
local function detectOperation(text)
	local lowerText = string.lower(text)
	
	if string.match(lowerText, "creat") or string.match(lowerText, "new script") then
		return "create"
	elseif string.match(lowerText, "create.*part") or string.match(lowerText, "create.*model") or string.match(lowerText, "create.*gui") then
		return "create_instance"
	elseif string.match(lowerText, "delet") or string.match(lowerText, "remov") then
		return "delete"
	elseif string.match(lowerText, "updat") or string.match(lowerText, "modif") or string.match(lowerText, "chang") then
		return "update"
	elseif string.match(lowerText, "refactor") then
		return "refactor"
	end
	
	return "unknown"
end

-- Instance tanımı extract et
local function extractInstanceDefinitions(text)
	local instances = {}
	
	-- "Create a Part/Model/ScreenGui named X in Y" pattern
	local pattern = "%b[]"
	
	-- JSON-like format: {type: "Part", name: "MyPart", parent: "Workspace", properties: {...}}
	for instanceDef in string.gmatch(text, "%{%s*[^}]*type[^}]*%}") do
		table.insert(instances, instanceDef)
	end
	
	return instances
end

-- Instance tanımını parse et
local function parseInstanceDefinition(definition)
	-- Simple JSON parsing simulation
	local instance = {
		type = "Part",
		name = "Instance",
		parent = "Workspace",
		properties = {}
	}
	
	-- Type extract
	local typeMatch = string.match(definition, '["\']?type["\']?%s*:%s*["\']([^"\']+)["\']')
	if typeMatch then
		instance.type = typeMatch
	end
	
	-- Name extract
	local nameMatch = string.match(definition, '["\']?name["\']?%s*:%s*["\']([^"\']+)["\']')
	if nameMatch then
		instance.name = nameMatch
	end
	
	-- Parent extract
	local parentMatch = string.match(definition, '["\']?parent["\']?%s*:%s*["\']([^"\']+)["\']')
	if parentMatch then
		instance.parent = parentMatch
	end
	
	return instance
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

-- Ana parse fonksiyonu (genişletilmiş)
function ResponseParser.parse(responseText)
	if not responseText or #responseText == 0 then
		return {
			hasCode = false,
			codeBlocks = {},
			operation = "none",
			explanation = "",
			scriptPath = nil,
			instanceDefinitions = {},
			duplicateWarning = false
		}
	end
	
	local codeBlocks = extractCodeBlocks(responseText)
	local operation = detectOperation(responseText)
	local scriptPath = extractScriptPath(responseText)
	local explanation = extractExplanation(responseText)
	local instanceDefinitions = extractInstanceDefinitions(responseText)
	
	-- Duplikasyon uyarısı
	local duplicateWarning = false
	if #codeBlocks > 3 then
		duplicateWarning = true -- Çok fazla kod bloğu
	end
	
	return {
		hasCode = #codeBlocks > 0,
		codeBlocks = codeBlocks,
		operation = operation,
		explanation = explanation,
		scriptPath = scriptPath,
		instanceDefinitions = instanceDefinitions,
		rawResponse = responseText,
		duplicateWarning = duplicateWarning
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
