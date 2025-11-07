--[[
	HTTPClient - HTTP İstekleri için Wrapper
	
	Rate limiting, timeout, error handling ve retry logic
	ile AI API çağrıları için optimize edilmiş HTTP client.
]]

local Config = require(script.Parent.Parent.Config)

local HTTPClient = {}
HTTPClient.__index = HTTPClient

-- Rate limiting için request tracker
local requestTimestamps = {}

-- Yeni HTTP client instance oluştur
function HTTPClient.new(logger)
	local self = setmetatable({}, HTTPClient)
	
	self._httpService = game:GetService("HttpService")
	self._logger = logger
	self._requestCount = 0
	
	return self
end

-- Rate limit kontrolü
function HTTPClient:_checkRateLimit()
	local now = tick()
	local oneMinuteAgo = now - 60
	
	-- 1 dakikadan eski istekleri temizle
	local validRequests = {}
	for _, timestamp in ipairs(requestTimestamps) do
		if timestamp > oneMinuteAgo then
			table.insert(validRequests, timestamp)
		end
	end
	requestTimestamps = validRequests
	
	-- Rate limit kontrolü
	if #requestTimestamps >= Config.RATE_LIMITS.MAX_REQUESTS_PER_MINUTE then
		return false, "Rate limit exceeded. Please wait."
	end
	
	-- Bu isteği kaydet
	table.insert(requestTimestamps, now)
	return true
end

-- Sleep function (wait için)
local function sleep(seconds)
	local start = tick()
	while tick() - start < seconds do
		task.wait()
	end
end

-- HTTP GET isteği
function HTTPClient:get(url, headers)
	local canProceed, errorMsg = self:_checkRateLimit()
	if not canProceed then
		return false, errorMsg
	end
	
	if self._logger then
		self._logger:debug("HTTP GET", { url = url })
	end
	
	local success, result = pcall(function()
		return self._httpService:GetAsync(url, false, headers or {})
	end)
	
	if success then
		return true, result
	else
		if self._logger then
			self._logger:error("HTTP GET failed", { url = url, error = result })
		end
		return false, result
	end
end

-- HTTP POST isteği
function HTTPClient:post(url, data, headers)
	local canProceed, errorMsg = self:_checkRateLimit()
	if not canProceed then
		return false, errorMsg
	end
	
	if self._logger then
		self._logger:debug("HTTP POST", { url = url })
	end
	
	local success, result = pcall(function()
		return self._httpService:PostAsync(url, data, Enum.HttpContentType.ApplicationJson, false, headers or {})
	end)
	
	if success then
		return true, result
	else
		if self._logger then
			self._logger:error("HTTP POST failed", { url = url, error = result })
		end
		return false, result
	end
end

-- Retry logic ile HTTP POST
function HTTPClient:postWithRetry(url, data, headers, retries)
	retries = retries or Config.RATE_LIMITS.RETRY_ATTEMPTS
	
	for attempt = 1, retries do
		local success, result = self:post(url, data, headers)
		
		if success then
			return true, result
		end
		
		-- Son deneme değilse bekle ve tekrar dene
		if attempt < retries then
			if self._logger then
				self._logger:warn("Request failed, retrying", {
					attempt = attempt,
					retries = retries
				})
			end
			
			sleep(Config.RATE_LIMITS.RETRY_DELAY * attempt)
		else
			return false, result
		end
	end
	
	return false, "Max retries exceeded"
end

-- JSON POST helper
function HTTPClient:postJSON(url, payload, headers)
	headers = headers or {}
	headers["Content-Type"] = "application/json"
	
	local jsonData = self._httpService:JSONEncode(payload)
	return self:postWithRetry(url, jsonData, headers)
end

-- Timeout ile istek gönder
function HTTPClient:requestWithTimeout(requestFunc, timeout)
	timeout = timeout or Config.RATE_LIMITS.REQUEST_TIMEOUT
	
	local completed = false
	local success, result, errorMsg
	
	-- Request'i ayrı thread'de çalıştır
	task.spawn(function()
		success, result = requestFunc()
		completed = true
	end)
	
	-- Timeout kontrolü
	local startTime = tick()
	while not completed and (tick() - startTime) < timeout do
		task.wait(0.1)
	end
	
	if not completed then
		return false, "Request timeout"
	end
	
	return success, result
end

-- AI API çağrısı (OpenAI format)
function HTTPClient:callOpenAI(apiKey, model, messages)
	local url = Config.API_ENDPOINTS.OPENAI
	
	local headers = {
		["Authorization"] = "Bearer " .. apiKey,
		["Content-Type"] = "application/json"
	}
	
	local payload = {
		model = model,
		messages = messages,
		temperature = 0.7,
		max_tokens = 4000
	}
	
	if self._logger then
		self._logger:logAPIRequest("OpenAI", url, payload)
	end
	
	local success, response = self:postJSON(url, payload, headers)
	
	if self._logger then
		self._logger:logAPIResponse("OpenAI", success, response)
	end
	
	if not success then
		return false, response
	end
	
	-- Parse response
	local decoded = self._httpService:JSONDecode(response)
	
	if decoded.choices and #decoded.choices > 0 then
		return true, decoded.choices[1].message.content
	else
		return false, "Invalid response format"
	end
end

-- AI API çağrısı (Claude format)
function HTTPClient:callClaude(apiKey, model, messages)
	local url = Config.API_ENDPOINTS.CLAUDE
	
	local headers = {
		["x-api-key"] = apiKey,
		["anthropic-version"] = "2023-06-01",
		["Content-Type"] = "application/json"
	}
	
	-- Claude formatına dönüştür (system message ayrı)
	local systemMessage = ""
	local claudeMessages = {}
	
	for _, msg in ipairs(messages) do
		if msg.role == "system" then
			systemMessage = msg.content
		else
			table.insert(claudeMessages, {
				role = msg.role,
				content = msg.content
			})
		end
	end
	
	local payload = {
		model = model,
		messages = claudeMessages,
		max_tokens = 4000,
		system = systemMessage
	}
	
	if self._logger then
		self._logger:logAPIRequest("Claude", url, payload)
	end
	
	local success, response = self:postJSON(url, payload, headers)
	
	if self._logger then
		self._logger:logAPIResponse("Claude", success, response)
	end
	
	if not success then
		return false, response
	end
	
	-- Parse response
	local decoded = self._httpService:JSONDecode(response)
	
	if decoded.content and #decoded.content > 0 then
		return true, decoded.content[1].text
	else
		return false, "Invalid response format"
	end
end

-- AI API çağrısı (Gemini format)
function HTTPClient:callGemini(apiKey, model, messages)
	local url = Config.API_ENDPOINTS.GEMINI .. "?key=" .. apiKey
	
	local headers = {
		["Content-Type"] = "application/json"
	}
	
	-- Gemini formatına dönüştür
	local contents = {}
	
	for _, msg in ipairs(messages) do
		local role = msg.role == "assistant" and "model" or "user"
		
		table.insert(contents, {
			role = role,
			parts = {
				{ text = msg.content }
			}
		})
	end
	
	local payload = {
		contents = contents,
		generationConfig = {
			temperature = 0.7,
			maxOutputTokens = 4000
		}
	}
	
	if self._logger then
		self._logger:logAPIRequest("Gemini", url, payload)
	end
	
	local success, response = self:postJSON(url, payload, headers)
	
	if self._logger then
		self._logger:logAPIResponse("Gemini", success, response)
	end
	
	if not success then
		return false, response
	end
	
	-- Parse response
	local decoded = self._httpService:JSONDecode(response)
	
	if decoded.candidates and #decoded.candidates > 0 then
		local candidate = decoded.candidates[1]
		if candidate.content and candidate.content.parts and #candidate.content.parts > 0 then
			return true, candidate.content.parts[1].text
		end
	end
	
	return false, "Invalid response format"
end

-- Request sayısını al
function HTTPClient:getRequestCount()
	return self._requestCount
end

-- Rate limit durumunu al
function HTTPClient:getRateLimitStatus()
	local now = tick()
	local oneMinuteAgo = now - 60
	
	local recentRequests = 0
	for _, timestamp in ipairs(requestTimestamps) do
		if timestamp > oneMinuteAgo then
			recentRequests = recentRequests + 1
		end
	end
	
	return {
		requests = recentRequests,
		limit = Config.RATE_LIMITS.MAX_REQUESTS_PER_MINUTE,
		remaining = math.max(0, Config.RATE_LIMITS.MAX_REQUESTS_PER_MINUTE - recentRequests)
	}
end

return HTTPClient
