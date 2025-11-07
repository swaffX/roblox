--[[
	Encryption - Secure Data Encryption/Decryption
	
	Provides Base64 encoding and XOR encryption for secure
	storage of sensitive data like API keys.
]]

local Encryption = {}

-- Base64 character set
local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Base64 encode
function Encryption.base64Encode(data)
	local result = {}
	local padding = ""
	
	for i = 1, #data, 3 do
		local byte1 = string.byte(data, i)
		local byte2 = string.byte(data, i + 1)
		local byte3 = string.byte(data, i + 2)
		
		local combined = byte1 * 65536
		
		if byte2 then
			combined = combined + byte2 * 256
		else
			padding = padding .. "="
		end
		
		if byte3 then
			combined = combined + byte3
		else
			if byte2 then
				padding = padding .. "="
			end
		end
		
		local b1 = math.floor(combined / 262144) % 64
		local b2 = math.floor(combined / 4096) % 64
		local b3 = math.floor(combined / 64) % 64
		local b4 = combined % 64
		
		table.insert(result, string.sub(base64Chars, b1 + 1, b1 + 1))
		table.insert(result, string.sub(base64Chars, b2 + 1, b2 + 1))
		
		if byte2 then
			table.insert(result, string.sub(base64Chars, b3 + 1, b3 + 1))
		end
		
		if byte3 then
			table.insert(result, string.sub(base64Chars, b4 + 1, b4 + 1))
		end
	end
	
	return table.concat(result) .. padding
end

-- Base64 decode
function Encryption.base64Decode(data)
	data = string.gsub(data, "[^" .. base64Chars .. "=]", "")
	
	local result = {}
	
	for i = 1, #data, 4 do
		local char1 = string.sub(data, i, i)
		local char2 = string.sub(data, i + 1, i + 1)
		local char3 = string.sub(data, i + 2, i + 2)
		local char4 = string.sub(data, i + 3, i + 3)
		
		local index1 = string.find(base64Chars, char1) - 1
		local index2 = string.find(base64Chars, char2) - 1
		local index3 = char3 ~= "=" and string.find(base64Chars, char3) - 1 or 0
		local index4 = char4 ~= "=" and string.find(base64Chars, char4) - 1 or 0
		
		local combined = index1 * 262144 + index2 * 4096 + index3 * 64 + index4
		
		local byte1 = math.floor(combined / 65536) % 256
		table.insert(result, string.char(byte1))
		
		if char3 ~= "=" then
			local byte2 = math.floor(combined / 256) % 256
			table.insert(result, string.char(byte2))
		end
		
		if char4 ~= "=" then
			local byte3 = combined % 256
			table.insert(result, string.char(byte3))
		end
	end
	
	return table.concat(result)
end

-- Generate a simple salt based on user and machine
function Encryption.generateSalt()
	local userId = game:GetService("StudioService"):GetUserId()
	local sessionId = game.JobId
	
	-- Combine multiple factors for better entropy
	local salt = string.format("%d_%s_%d", 
		userId,
		sessionId,
		tick()
	)
	
	-- Hash the salt using simple XOR folding
	local hashed = 0
	for i = 1, #salt do
		hashed = bit32.bxor(hashed * 31 + string.byte(salt, i), 0x5A5A5A5A)
	end
	
	return tostring(hashed)
end

-- XOR encryption/decryption
function Encryption.xorCrypt(data, key)
	if not data or #data == 0 then
		return ""
	end
	
	if not key or #key == 0 then
		return data
	end
	
	local result = {}
	local keyLen = #key
	
	for i = 1, #data do
		local dataByte = string.byte(data, i)
		local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
		local encrypted = bit32.bxor(dataByte, keyByte)
		table.insert(result, string.char(encrypted))
	end
	
	return table.concat(result)
end

-- Encrypt data (XOR + Base64)
function Encryption.encrypt(plaintext, key)
	if not plaintext or #plaintext == 0 then
		return ""
	end
	
	-- Generate salt if no key provided
	if not key then
		key = Encryption.generateSalt()
	end
	
	-- XOR encrypt
	local encrypted = Encryption.xorCrypt(plaintext, key)
	
	-- Base64 encode
	local encoded = Encryption.base64Encode(encrypted)
	
	return encoded
end

-- Decrypt data (Base64 + XOR)
function Encryption.decrypt(ciphertext, key)
	if not ciphertext or #ciphertext == 0 then
		return ""
	end
	
	-- Generate salt if no key provided
	if not key then
		key = Encryption.generateSalt()
	end
	
	local success, result = pcall(function()
		-- Base64 decode
		local decoded = Encryption.base64Decode(ciphertext)
		
		-- XOR decrypt (same as encrypt since XOR is symmetric)
		local decrypted = Encryption.xorCrypt(decoded, key)
		
		return decrypted
	end)
	
	if success then
		return result
	else
		warn("Decryption failed:", result)
		return ""
	end
end

-- Secure hash function (simple implementation)
function Encryption.hash(data)
	local hash = 0
	
	for i = 1, #data do
		local byte = string.byte(data, i)
		hash = bit32.bxor(hash * 31 + byte, 0xDEADBEEF)
		hash = bit32.band(hash, 0xFFFFFFFF)
	end
	
	return string.format("%08X", hash)
end

-- Verify encrypted data integrity
function Encryption.verify(plaintext, ciphertext, key)
	local decrypted = Encryption.decrypt(ciphertext, key)
	return decrypted == plaintext
end

return Encryption
