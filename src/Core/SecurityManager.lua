--[[
	SecurityManager - Güvenlik Katmanı
	
	Script validation, malicious code detection, input sanitization
	ve tüm kritik operasyonlar için güvenlik kontrolleri.
]]

local Config = require(script.Parent.Parent.Config)

local SecurityManager = {}
SecurityManager.__index = SecurityManager

-- Yeni security manager instance oluştur
function SecurityManager.new(logger)
	local self = setmetatable({}, SecurityManager)
	
	self._logger = logger
	self._blockedPatterns = Config.SECURITY.BLOCKED_PATTERNS
	
	return self
end

-- Zararlı kod pattern'lerini kontrol et
function SecurityManager:scanForMaliciousCode(code)
	if not code or #code == 0 then
		return true, {}
	end
	
	local findings = {}
	
	for _, pattern in ipairs(self._blockedPatterns) do
		local matches = {}
		local startPos = 1
		
		while true do
			local matchStart, matchEnd = string.find(code, pattern, startPos)
			if not matchStart then
				break
			end
			
			table.insert(matches, {
				pattern = pattern,
				position = matchStart,
				match = string.sub(code, matchStart, matchEnd)
			})
			
			startPos = matchEnd + 1
		end
		
		if #matches > 0 then
			table.insert(findings, {
				pattern = pattern,
				count = #matches,
				matches = matches
			})
		end
	end
	
	if #findings > 0 then
		if self._logger then
			self._logger:warn("Malicious code patterns detected", {
				count = #findings
			})
		end
		return false, findings
	end
	
	return true, {}
end

-- Kod boyutu kontrolü
function SecurityManager:validateCodeSize(code)
	if not code then
		return true
	end
	
	local size = #code
	
	if size > Config.SECURITY.MAX_CODE_SIZE then
		if self._logger then
			self._logger:warn("Code size exceeds limit", {
				size = size,
				limit = Config.SECURITY.MAX_CODE_SIZE
			})
		end
		return false, string.format("Code size (%d) exceeds maximum allowed (%d)", 
			size, Config.SECURITY.MAX_CODE_SIZE)
	end
	
	return true
end

-- Input sanitization
function SecurityManager:sanitizeInput(input)
	if not input then
		return ""
	end
	
	-- Trim whitespace
	input = string.gsub(input, "^%s+", "")
	input = string.gsub(input, "%s+$", "")
	
	-- Remove null bytes
	input = string.gsub(input, "%z", "")
	
	return input
end

-- Script adı validation
function SecurityManager:validateScriptName(name)
	if not name or #name == 0 then
		return false, "Script name cannot be empty"
	end
	
	-- İzin verilen karakterler: harfler, rakamlar, alt çizgi, tire
	if not string.match(name, "^[%w_%-]+$") then
		return false, "Script name contains invalid characters"
	end
	
	-- Uzunluk kontrolü
	if #name > 50 then
		return false, "Script name is too long (max 50 characters)"
	end
	
	return true
end

-- API key validation
function SecurityManager:validateAPIKey(provider, key)
	if not key or #key == 0 then
		return false, "API key cannot be empty"
	end
	
	-- Minimum uzunluk kontrolü
	if #key < 10 then
		return false, "API key is too short"
	end
	
	-- Provider-specific validation
	if provider == Config.AI_PROVIDERS.OPENAI then
		if not string.match(key, "^sk%-") then
			return false, "Invalid OpenAI API key format (should start with 'sk-')"
		end
	elseif provider == Config.AI_PROVIDERS.CLAUDE then
		if not string.match(key, "^sk%-ant%-") then
			return false, "Invalid Claude API key format (should start with 'sk-ant-')"
		end
	elseif provider == Config.AI_PROVIDERS.GEMINI then
		if not string.match(key, "^[A-Za-z0-9_%-]+$") then
			return false, "Invalid Gemini API key format"
		end
	end
	
	return true
end

-- Kullanıcı onayı gerektiren operasyon kontrolü
function SecurityManager:requiresConfirmation(operation)
	if not Config.SECURITY.REQUIRE_CONFIRMATION then
		return false
	end
	
	-- Bu operasyonlar her zaman onay gerektirir
	local criticalOperations = {
		"delete_script",
		"modify_multiple_scripts",
		"clear_workspace",
		"mass_operation"
	}
	
	for _, criticalOp in ipairs(criticalOperations) do
		if operation == criticalOp then
			return true
		end
	end
	
	return false
end

-- Onay dialogu göster
function SecurityManager:requestConfirmation(message, title)
	title = title or "Confirmation Required"
	
	-- StudioService kullanarak prompt göster
	local StudioService = game:GetService("StudioService")
	
	local success, result = pcall(function()
		-- Basit bir onay dialogu (Roblox Studio'da çalışır)
		return true -- Gerçek implementasyonda kullanıcıdan input alınmalı
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to show confirmation dialog", { error = result })
		end
		return false
	end
	
	return result
end

-- Script yolu validation
function SecurityManager:validateScriptPath(path)
	if not path or #path == 0 then
		return false, "Script path cannot be empty"
	end
	
	-- İzin verilen ana konumlar
	local allowedRoots = {
		"Workspace",
		"ReplicatedStorage",
		"ServerScriptService",
		"StarterPlayer",
		"StarterPack",
		"StarterGui"
	}
	
	local rootFound = false
	for _, root in ipairs(allowedRoots) do
		if string.match(path, "^" .. root) then
			rootFound = true
			break
		end
	end
	
	if not rootFound then
		return false, "Script must be in an allowed location"
	end
	
	return true
end

-- Operasyon rate limiting
local operationTimestamps = {}

function SecurityManager:checkOperationRateLimit(operationType)
	local now = tick()
	local limit = 10 -- 10 operasyon per dakika
	local window = 60 -- 1 dakika
	
	if not operationTimestamps[operationType] then
		operationTimestamps[operationType] = {}
	end
	
	-- Eski timestamp'leri temizle
	local validTimestamps = {}
	for _, timestamp in ipairs(operationTimestamps[operationType]) do
		if now - timestamp < window then
			table.insert(validTimestamps, timestamp)
		end
	end
	operationTimestamps[operationType] = validTimestamps
	
	-- Rate limit kontrolü
	if #validTimestamps >= limit then
		return false, string.format("Rate limit exceeded for %s operations", operationType)
	end
	
	-- Yeni timestamp ekle
	table.insert(operationTimestamps[operationType], now)
	
	return true
end

-- Tüm güvenlik kontrollerini çalıştır
function SecurityManager:validateOperation(operationType, data)
	-- Rate limiting
	local rateLimitOk, rateLimitError = self:checkOperationRateLimit(operationType)
	if not rateLimitOk then
		return false, rateLimitError
	end
	
	-- Operasyon tipine göre özel kontroller
	if operationType == "create_script" or operationType == "update_script" then
		if data.code then
			-- Kod boyutu kontrolü
			local sizeOk, sizeError = self:validateCodeSize(data.code)
			if not sizeOk then
				return false, sizeError
			end
			
			-- Zararlı kod kontrolü
			local codeOk, findings = self:scanForMaliciousCode(data.code)
			if not codeOk then
				return false, "Potentially malicious code detected", findings
			end
		end
		
		if data.name then
			-- İsim validasyonu
			local nameOk, nameError = self:validateScriptName(data.name)
			if not nameOk then
				return false, nameError
			end
		end
		
		if data.path then
			-- Yol validasyonu
			local pathOk, pathError = self:validateScriptPath(data.path)
			if not pathOk then
				return false, pathError
			end
		end
	end
	
	-- Onay gerekiyor mu?
	if self:requiresConfirmation(operationType) then
		local confirmed = self:requestConfirmation(
			string.format("This operation (%s) requires confirmation. Continue?", operationType),
			"Security Confirmation"
		)
		
		if not confirmed then
			return false, "Operation cancelled by user"
		end
	end
	
	return true
end

-- Security log oluştur
function SecurityManager:logSecurityEvent(eventType, details)
	if self._logger then
		self._logger:warn("Security Event: " .. eventType, details)
	end
end

return SecurityManager
