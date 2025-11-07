--[[
	CodeAnalyzer - Kod Analiz Modülü
	
	Workspace'i analiz eder, dependency mapping, function/variable inventory,
	semantic context building ve AI için genişletilmiş context yapılandırması yapar.
]]

local CodeAnalyzer = {}
CodeAnalyzer.__index = CodeAnalyzer

function CodeAnalyzer.new(workspaceManager, logger)
	local self = setmetatable({}, CodeAnalyzer)
	
	self._workspace = workspaceManager
	self._logger = logger
	self._semanticCache = {} -- Semantic analiz cache'i
	
	return self
end

-- Function tanımlarını bul
local function extractFunctions(source)
	local functions = {}
	
	-- function name() pattern
	for funcName in string.gmatch(source, "function%s+([%w_]+)%s*%(") do
		table.insert(functions, funcName)
	end
	
	-- local function name() pattern
	for funcName in string.gmatch(source, "local%s+function%s+([%w_]+)%s*%(") do
		table.insert(functions, funcName)
	end
	
	return functions
end

-- Variable tanımlarını bul
local function extractVariables(source)
	local variables = {}
	
	-- local var = pattern
	for varName in string.gmatch(source, "local%s+([%w_]+)%s*=") do
		table.insert(variables, varName)
	end
	
	return variables
end

-- Require statements bul
local function extractRequires(source)
	local requires = {}
	
	for req in string.gmatch(source, 'require%s*%(([^%)]+)%)') do
		table.insert(requires, req)
	end
	
	return requires
end

-- Kod karmaşıklığını hesapla (basit metrik)
local function calculateComplexity(source)
	local complexity = 1
	
	-- Control flow statements
	local keywords = {"if", "while", "for", "repeat", "function"}
	for _, keyword in ipairs(keywords) do
		local _, count = string.gsub(source, "%f[%a]" .. keyword .. "%f[%A]", "")
		complexity = complexity + count
	end
	
	return complexity
end

-- Tek bir script analiz et
function CodeAnalyzer:analyzeScript(scriptInstance)
	if not scriptInstance then
		return nil
	end
	
	local source = self._workspace:readScript(scriptInstance)
	if not source then
		return nil
	end
	
	local metadata = self._workspace:getScriptMetadata(scriptInstance)
	
	return {
		metadata = metadata,
		functions = extractFunctions(source),
		variables = extractVariables(source),
		requires = extractRequires(source),
		complexity = calculateComplexity(source),
		lineCount = select(2, string.gsub(source, "\n", "\n")) + 1,
		characterCount = #source
	}
end

-- Tüm workspace'i analiz et
function CodeAnalyzer:analyzeWorkspace(parent)
	local allScripts = self._workspace:findAllScripts(parent)
	local analysis = {
		totalScripts = #allScripts,
		scripts = {},
		summary = {
			totalLines = 0,
			totalFunctions = 0,
			totalComplexity = 0
		}
	}
	
	for _, scriptData in ipairs(allScripts) do
		local scriptAnalysis = self:analyzeScript(scriptData.instance)
		if scriptAnalysis then
			table.insert(analysis.scripts, scriptAnalysis)
			
			analysis.summary.totalLines = analysis.summary.totalLines + scriptAnalysis.lineCount
			analysis.summary.totalFunctions = analysis.summary.totalFunctions + #scriptAnalysis.functions
			analysis.summary.totalComplexity = analysis.summary.totalComplexity + scriptAnalysis.complexity
		end
	end
	
	return analysis
end

-- AI için context oluştur
function CodeAnalyzer:buildAIContext(parent, maxScripts)
	maxScripts = maxScripts or 10
	
	local allScripts = self._workspace:findAllScripts(parent)
	local context = {
		projectSummary = string.format("Project has %d scripts", #allScripts),
		scripts = {}
	}
	
	-- En önemli scriptleri seç (boyut ve karmaşıklığa göre)
	local prioritizedScripts = {}
	for _, scriptData in ipairs(allScripts) do
		local analysis = self:analyzeScript(scriptData.instance)
		if analysis then
			table.insert(prioritizedScripts, {
				data = scriptData,
				analysis = analysis,
				score = analysis.complexity + (analysis.lineCount / 10)
			})
		end
	end
	
	table.sort(prioritizedScripts, function(a, b)
		return a.score > b.score
	end)
	
	-- İlk N script'i context'e ekle
	for i = 1, math.min(maxScripts, #prioritizedScripts) do
		local item = prioritizedScripts[i]
		table.insert(context.scripts, {
			name = item.data.name,
			path = item.data.path,
			type = item.data.type,
			summary = string.format(
				"%d lines, %d functions, complexity %d",
				item.analysis.lineCount,
				#item.analysis.functions,
				item.analysis.complexity
			)
		})
	end
	
	return context
end

-- Context'i string olarak formatla
function CodeAnalyzer:formatContextForAI(context)
	local lines = {
		"=== Project Context ===",
		context.projectSummary,
		"",
		"Key Scripts:"
	}
	
	for _, script in ipairs(context.scripts) do
		table.insert(lines, string.format("- %s (%s): %s", script.name, script.type, script.summary))
	end
	
	return table.concat(lines, "\n")
end

-- Semantic analiz - Projedeki main sistemleri tespit et
function CodeAnalyzer:performSemanticAnalysis(parent)
	parent = parent or game
	
	local analysis = {
		systems = {},
		patterns = {},
		dependencies = {},
		architectureType = "unknown"
	}
	
	local allScripts = self._workspace:findAllScripts(parent)
	local scriptNames = {}
	local scriptSources = {}
	
	for _, scriptData in ipairs(allScripts) do
		table.insert(scriptNames, string.lower(scriptData.name))
		scriptSources[scriptData.name] = scriptData.source
	end
	
	-- Sistem tespiti (adlara ve içeriğe göre)
	local systemPatterns = {
		gameManager = {"game", "manager", "main"},
		playerHandler = {"player", "character", "spawn"},
		uiSystem = {"ui", "gui", "menu", "hud"},
		combatSystem = {"combat", "fight", "damage", "health"},
		inventorySystem = {"inventory", "item", "storage"},
		levelSystem = {"level", "experience", "exp"},
		networkSystem = {"network", "remote", "replicate"},
		physicsSystem = {"physics", "velocity", "gravity"},
		soundSystem = {"sound", "audio", "music"},
		saveSystem = {"save", "load", "database", "data"}
	}
	
	for systemName, patterns in pairs(systemPatterns) do
		for _, scriptName in ipairs(scriptNames) do
			for _, pattern in ipairs(patterns) do
				if string.match(scriptName, pattern) then
					if not analysis.systems[systemName] then
						analysis.systems[systemName] = {}
					end
					table.insert(analysis.systems[systemName], scriptName)
					break
				end
			end
		end
	end
	
	-- Pattern tespiti
	local patternChecks = {
		["Event-Driven"] = function(source)
			return string.match(source, "Signal") or string.match(source, ":Fire%(") or string.match(source, ":Wait%(")
		end,
		["MVC Pattern"] = function(source)
			return string.match(source, "Controller") or string.match(source, "Model") or string.match(source, "View")
		end,
		["OOP Pattern"] = function(source)
			return string.match(source, "%.__index") or string.match(source, "setmetatable")
		end,
		["Functional Pattern"] = function(source)
			return string.match(source, "local%s+function") and string.match(source, "return%s+{")
		end
	}
	
	for scriptName, source in pairs(scriptSources) do
		for patternName, checker in pairs(patternChecks) do
			if checker(source) then
				if not analysis.patterns[patternName] then
					analysis.patterns[patternName] = 0
				end
				analysis.patterns[patternName] = analysis.patterns[patternName] + 1
			end
		end
	end
	
	-- Mimari tipi tespiti
	local mvcCount = analysis.patterns["MVC Pattern"] or 0
	local oopCount = analysis.patterns["OOP Pattern"] or 0
	local eventCount = analysis.patterns["Event-Driven"] or 0
	
	if mvcCount > eventCount and mvcCount > oopCount then
		analysis.architectureType = "MVC-based"
	elseif oopCount > eventCount then
		analysis.architectureType = "OOP-based"
	elseif eventCount > 0 then
		analysis.architectureType = "Event-driven"
	end
	
	return analysis
end

-- Genişletilmiş AI context oluştur (daha geniş bağlam)
function CodeAnalyzer:buildExtendedAIContext(parent, maxScripts)
	maxScripts = maxScripts or 20 -- Varsayılan 20, daha fazla script
	
	local allScripts = self._workspace:findAllScripts(parent)
	local semanticAnalysis = self:performSemanticAnalysis(parent)
	
	local context = {
		projectSummary = string.format("Project has %d scripts", #allScripts),
		semanticAnalysis = semanticAnalysis,
		scripts = {},
		allInstances = {},
		dependencies = {}
	}
	
	-- En önemli scriptleri seç
	local prioritizedScripts = {}
	for _, scriptData in ipairs(allScripts) do
		local analysis = self:analyzeScript(scriptData.instance)
		if analysis then
			table.insert(prioritizedScripts, {
				data = scriptData,
				analysis = analysis,
				score = analysis.complexity + (analysis.lineCount / 10)
			})
		end
	end
	
	table.sort(prioritizedScripts, function(a, b)
		return a.score > b.score
	end)
	
	-- İlk N script'i context'e ekle
	for i = 1, math.min(maxScripts, #prioritizedScripts) do
		local item = prioritizedScripts[i]
		table.insert(context.scripts, {
			name = item.data.name,
			path = item.data.path,
			type = item.data.type,
			summary = string.format(
				"%d lines, %d functions, complexity %d",
				item.analysis.lineCount,
				#item.analysis.functions,
				item.analysis.complexity
			),
			functions = table.concat(item.analysis.functions, ", "),
			variables = table.concat(item.analysis.variables, ", ")
		})
	end
	
	-- Tüm Instance'ları (UI, Model, Parts vb.) bul
	local allInstances = self._workspace:findAllInstances(parent)
	local instanceTypes = {}
	
	for _, instData in ipairs(allInstances) do
		if not instanceTypes[instData.type] then
			instanceTypes[instData.type] = 0
		end
		instanceTypes[instData.type] = instanceTypes[instData.type] + 1
	end
	
	context.allInstances = instanceTypes
	
	return context
end

-- Genişletilmiş context'i string olarak formatla
function CodeAnalyzer:formatExtendedContextForAI(context)
	local lines = {
		"=== EXTENDED PROJECT CONTEXT ===",
		context.projectSummary,
		""
	}
	
	-- Semantic analiz
	if context.semanticAnalysis then
		table.insert(lines, "=== DETECTED SYSTEMS ===")
		for systemName, scripts in pairs(context.semanticAnalysis.systems) do
			if #scripts > 0 then
				table.insert(lines, string.format("- %s: %s", systemName, table.concat(scripts, ", ")))
			end
		end
		table.insert(lines, "")
		
		table.insert(lines, string.format("=== ARCHITECTURE ==="))
		table.insert(lines, "Type: " .. context.semanticAnalysis.architectureType)
		table.insert(lines, "")
	end
	
	-- Scriptler
	table.insert(lines, "=== KEY SCRIPTS ===")
	for _, script in ipairs(context.scripts) do
		table.insert(lines, string.format("- %s (%s): %s", script.name, script.type, script.summary))
		if #script.functions > 0 then
			table.insert(lines, "  Functions: " .. script.functions)
		end
	end
	table.insert(lines, "")
	
	-- Instance türleri
	if context.allInstances then
		table.insert(lines, "=== AVAILABLE INSTANCE TYPES ===")
		for instanceType, count in pairs(context.allInstances) do
			table.insert(lines, string.format("- %s: %d", instanceType, count))
		end
		table.insert(lines, "")
	end
	
	table.insert(lines, "=== INSTRUCTIONS ===")
	table.insert(lines, "Consider the project architecture and detected systems when responding.")
	table.insert(lines, "You can create Parts, Models, ScreenGuis, Scripts, and other Roblox instances.")
	table.insert(lines, "Always specify the parent container when creating instances.")
	
	return table.concat(lines, "\n")
end

return CodeAnalyzer
