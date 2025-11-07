--[[
	Logger - Centralized Logging System
	
	Provides debug, info, warning and error level logging
	with support for console output and persistent storage.
]]

local Config = require(script.Parent.Parent.Config)

local Logger = {}
Logger.__index = Logger

-- Log Levels
local LogLevel = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4
}

local LogLevelNames = {
	[LogLevel.DEBUG] = "DEBUG",
	[LogLevel.INFO] = "INFO",
	[LogLevel.WARN] = "WARN",
	[LogLevel.ERROR] = "ERROR"
}

-- Convert string log level to numeric
local function getLogLevelValue(levelName)
	for value, name in pairs(LogLevelNames) do
		if name == levelName then
			return value
		end
	end
	return LogLevel.INFO
end

-- Format timestamp
local function formatTimestamp()
	return os.date("%Y-%m-%d %H:%M:%S")
end

-- Format log message
local function formatMessage(level, message, context)
	local timestamp = formatTimestamp()
	local levelName = LogLevelNames[level] or "INFO"
	local contextStr = ""
	
	if context then
		local parts = {}
		for key, value in pairs(context) do
			table.insert(parts, string.format("%s=%s", key, tostring(value)))
		end
		contextStr = " [" .. table.concat(parts, ", ") .. "]"
	end
	
	return string.format("[%s] [%s]%s %s", timestamp, levelName, contextStr, message)
end

-- Create new logger instance
function Logger.new(plugin)
	local self = setmetatable({}, Logger)
	
	self._plugin = plugin
	self._enabled = Config.DEBUG.ENABLED
	self._minLevel = getLogLevelValue(Config.DEBUG.LOG_LEVEL)
	self._logs = {}
	self._maxLogs = 1000
	
	return self
end

-- Internal log method
function Logger:_log(level, message, context)
	if not self._enabled then
		return
	end
	
	if level < self._minLevel then
		return
	end
	
	local formattedMessage = formatMessage(level, message, context)
	
	-- Output to console
	if level == LogLevel.ERROR then
		warn(formattedMessage)
	else
		print(formattedMessage)
	end
	
	-- Store in memory
	table.insert(self._logs, {
		timestamp = tick(),
		level = level,
		message = message,
		context = context,
		formatted = formattedMessage
	})
	
	-- Trim logs if exceeds max
	if #self._logs > self._maxLogs then
		table.remove(self._logs, 1)
	end
end

-- Public logging methods
function Logger:debug(message, context)
	self:_log(LogLevel.DEBUG, message, context)
end

function Logger:info(message, context)
	self:_log(LogLevel.INFO, message, context)
end

function Logger:warn(message, context)
	self:_log(LogLevel.WARN, message, context)
end

function Logger:error(message, context)
	self:_log(LogLevel.ERROR, message, context)
end

-- Log API request
function Logger:logAPIRequest(provider, endpoint, payload)
	if not Config.DEBUG.LOG_API_REQUESTS then
		return
	end
	
	self:debug("API Request", {
		provider = provider,
		endpoint = endpoint,
		payload_size = #game:GetService("HttpService"):JSONEncode(payload)
	})
end

-- Log API response
function Logger:logAPIResponse(provider, success, responseData)
	if not Config.DEBUG.LOG_API_RESPONSES then
		return
	end
	
	local context = {
		provider = provider,
		success = success
	}
	
	if responseData then
		context.response_size = #tostring(responseData)
	end
	
	if success then
		self:debug("API Response Success", context)
	else
		self:error("API Response Failed", context)
	end
end

-- Get all logs
function Logger:getLogs(level)
	if level then
		local filtered = {}
		local levelValue = getLogLevelValue(level)
		
		for _, log in ipairs(self._logs) do
			if log.level >= levelValue then
				table.insert(filtered, log)
			end
		end
		
		return filtered
	end
	
	return self._logs
end

-- Clear logs
function Logger:clear()
	self._logs = {}
	self:info("Logs cleared")
end

-- Export logs to string
function Logger:exportLogs()
	local lines = {}
	
	for _, log in ipairs(self._logs) do
		table.insert(lines, log.formatted)
	end
	
	return table.concat(lines, "\n")
end

-- Enable/disable logging
function Logger:setEnabled(enabled)
	self._enabled = enabled
	self:info(enabled and "Logging enabled" or "Logging disabled")
end

-- Set minimum log level
function Logger:setLogLevel(levelName)
	self._minLevel = getLogLevelValue(levelName)
	self:info("Log level set to " .. levelName)
end

return Logger
