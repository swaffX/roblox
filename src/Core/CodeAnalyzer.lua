--[[
	CodeAnalyzer - Kod Analiz Modülü
	
	Workspace'i analiz eder, dependency mapping, function/variable inventory
	ve AI için context building yapar.
]]

local CodeAnalyzer = {}
CodeAnalyzer.__index = CodeAnalyzer

function CodeAnalyzer.new(workspaceManager, logger)
	local self = setmetatable({}, CodeAnalyzer)
	
	self._workspace = workspaceManager
	self._logger = logger
	
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

return CodeAnalyzer
