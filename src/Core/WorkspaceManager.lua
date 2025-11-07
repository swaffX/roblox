--[[
	WorkspaceManager - Workspace Yönetimi
	
	Workspace üzerinde CRUD operasyonları yapan modül.
	Script okuma/yazma/oluşturma/silme/taşıma işlemleri.
]]

local WorkspaceManager = {}
WorkspaceManager.__index = WorkspaceManager

-- Yeni workspace manager instance oluştur
function WorkspaceManager.new(logger, securityManager)
	local self = setmetatable({}, WorkspaceManager)
	
	self._logger = logger
	self._security = securityManager
	self._game = game
	
	return self
end

-- Script tiplerini tanımla
local SCRIPT_TYPES = {
	Script = "Script",
	LocalScript = "LocalScript",
	ModuleScript = "ModuleScript"
}

-- Instance'ın script olup olmadığını kontrol et
local function isScript(instance)
	return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

-- Instance'ın tam yolunu al
local function getFullPath(instance)
	local path = {}
	local current = instance
	
	while current and current ~= game do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	
	return table.concat(path, ".")
end

-- Tüm scriptleri bul (recursive)
function WorkspaceManager:findAllScripts(parent)
	parent = parent or game
	local scripts = {}
	
	local function searchRecursive(container)
		for _, child in ipairs(container:GetChildren()) do
			if isScript(child) then
				table.insert(scripts, {
					instance = child,
					name = child.Name,
					type = child.ClassName,
					path = getFullPath(child),
					source = child.Source
				})
			end
			
			-- Recursive search
			if child:IsA("Folder") or child:IsA("Model") or child:GetChildren() then
				searchRecursive(child)
			end
		end
	end
	
	searchRecursive(parent)
	return scripts
end

-- Yol ile script bul
function WorkspaceManager:findScriptByPath(path)
	local parts = {}
	for part in string.gmatch(path, "[^%.]+") do
		table.insert(parts, part)
	end
	
	if #parts == 0 then
		return nil
	end
	
	-- İlk part service olmalı
	local current = game:GetService(parts[1])
	if not current then
		current = game:FindFirstChild(parts[1])
	end
	
	if not current then
		return nil
	end
	
	-- Devam eden path'i takip et
	for i = 2, #parts do
		current = current:FindFirstChild(parts[i])
		if not current then
			return nil
		end
	end
	
	if isScript(current) then
		return current
	end
	
	return nil
end

-- Script oku
function WorkspaceManager:readScript(scriptInstance)
	if not scriptInstance then
		return nil, "Script instance is nil"
	end
	
	if not isScript(scriptInstance) then
		return nil, "Instance is not a script"
	end
	
	local success, source = pcall(function()
		return scriptInstance.Source
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to read script", {
				name = scriptInstance.Name,
				error = source
			})
		end
		return nil, source
	end
	
	return source
end

-- Script yaz
function WorkspaceManager:writeScript(scriptInstance, newSource)
	if not scriptInstance then
		return false, "Script instance is nil"
	end
	
	if not isScript(scriptInstance) then
		return false, "Instance is not a script"
	end
	
	-- Güvenlik kontrolü
	if self._security then
		local isValid, error = self._security:validateOperation("update_script", {
			code = newSource,
			name = scriptInstance.Name
		})
		
		if not isValid then
			return false, error
		end
	end
	
	local success, error = pcall(function()
		scriptInstance.Source = newSource
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to write script", {
				name = scriptInstance.Name,
				error = error
			})
		end
		return false, error
	end
	
	if self._logger then
		self._logger:info("Script updated", { name = scriptInstance.Name })
	end
	
	return true
end

-- Yeni script oluştur
function WorkspaceManager:createScript(parent, scriptName, scriptType, source)
	scriptType = scriptType or SCRIPT_TYPES.Script
	source = source or ""
	
	if not parent then
		return nil, "Parent instance is nil"
	end
	
	-- Güvenlik kontrolü
	if self._security then
		local isValid, error = self._security:validateOperation("create_script", {
			code = source,
			name = scriptName,
			path = getFullPath(parent)
		})
		
		if not isValid then
			return nil, error
		end
	end
	
	-- Script oluştur
	local success, result = pcall(function()
		local newScript = Instance.new(scriptType)
		newScript.Name = scriptName
		newScript.Source = source
		newScript.Parent = parent
		return newScript
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to create script", {
				name = scriptName,
				type = scriptType,
				error = result
			})
		end
		return nil, result
	end
	
	if self._logger then
		self._logger:info("Script created", {
			name = scriptName,
			type = scriptType,
			path = getFullPath(result)
		})
	end
	
	return result
end

-- Script sil
function WorkspaceManager:deleteScript(scriptInstance)
	if not scriptInstance then
		return false, "Script instance is nil"
	end
	
	if not isScript(scriptInstance) then
		return false, "Instance is not a script"
	end
	
	-- Güvenlik kontrolü
	if self._security then
		local isValid, error = self._security:validateOperation("delete_script", {
			name = scriptInstance.Name
		})
		
		if not isValid then
			return false, error
		end
	end
	
	local scriptName = scriptInstance.Name
	
	local success, error = pcall(function()
		scriptInstance:Destroy()
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to delete script", {
				name = scriptName,
				error = error
			})
		end
		return false, error
	end
	
	if self._logger then
		self._logger:info("Script deleted", { name = scriptName })
	end
	
	return true
end

-- Script taşı
function WorkspaceManager:moveScript(scriptInstance, newParent)
	if not scriptInstance then
		return false, "Script instance is nil"
	end
	
	if not newParent then
		return false, "New parent is nil"
	end
	
	if not isScript(scriptInstance) then
		return false, "Instance is not a script"
	end
	
	local oldPath = getFullPath(scriptInstance)
	
	local success, error = pcall(function()
		scriptInstance.Parent = newParent
	end)
	
	if not success then
		if self._logger then
			self._logger:error("Failed to move script", {
				name = scriptInstance.Name,
				from = oldPath,
				error = error
			})
		end
		return false, error
	end
	
	if self._logger then
		self._logger:info("Script moved", {
			name = scriptInstance.Name,
			from = oldPath,
			to = getFullPath(scriptInstance)
		})
	end
	
	return true
end

-- Script kopyala
function WorkspaceManager:copyScript(scriptInstance, newParent, newName)
	if not scriptInstance then
		return nil, "Script instance is nil"
	end
	
	if not isScript(scriptInstance) then
		return nil, "Instance is not a script"
	end
	
	newName = newName or scriptInstance.Name .. "_Copy"
	
	local source, error = self:readScript(scriptInstance)
	if not source then
		return nil, error
	end
	
	return self:createScript(
		newParent or scriptInstance.Parent,
		newName,
		scriptInstance.ClassName,
		source
	)
end

-- Script metadata al
function WorkspaceManager:getScriptMetadata(scriptInstance)
	if not scriptInstance then
		return nil
	end
	
	if not isScript(scriptInstance) then
		return nil
	end
	
	local source = self:readScript(scriptInstance)
	
	return {
		name = scriptInstance.Name,
		type = scriptInstance.ClassName,
		path = getFullPath(scriptInstance),
		parent = scriptInstance.Parent and scriptInstance.Parent.Name or "nil",
		sourceLength = source and #source or 0,
		enabled = scriptInstance:IsA("Script") and scriptInstance.Enabled or nil,
		runContext = scriptInstance:IsA("Script") and tostring(scriptInstance.RunContext) or nil
	}
end

-- Workspace snapshot al (backup için)
function WorkspaceManager:createSnapshot(parent)
	parent = parent or game
	
	local snapshot = {
		timestamp = tick(),
		scripts = {}
	}
	
	local allScripts = self:findAllScripts(parent)
	
	for _, scriptData in ipairs(allScripts) do
		table.insert(snapshot.scripts, {
			path = scriptData.path,
			name = scriptData.name,
			type = scriptData.type,
			source = scriptData.source
		})
	end
	
	if self._logger then
		self._logger:info("Snapshot created", {
			scriptCount = #snapshot.scripts
		})
	end
	
	return snapshot
end

-- Snapshot'tan geri yükle
function WorkspaceManager:restoreFromSnapshot(snapshot)
	if not snapshot or not snapshot.scripts then
		return false, "Invalid snapshot"
	end
	
	local restored = 0
	local failed = 0
	
	for _, scriptData in ipairs(snapshot.scripts) do
		-- Path'den parent bul
		local pathParts = {}
		for part in string.gmatch(scriptData.path, "[^%.]+") do
			table.insert(pathParts, part)
		end
		
		-- Son part script adı, diğerleri path
		local scriptName = table.remove(pathParts)
		
		-- Parent'ı bul veya oluştur
		local parent = game
		for _, part in ipairs(pathParts) do
			local child = parent:FindFirstChild(part)
			if not child then
				-- Parent yoksa oluştur
				child = Instance.new("Folder")
				child.Name = part
				child.Parent = parent
			end
			parent = child
		end
		
		-- Script'i oluştur
		local script, error = self:createScript(
			parent,
			scriptName,
			scriptData.type,
			scriptData.source
		)
		
		if script then
			restored = restored + 1
		else
			failed = failed + 1
			if self._logger then
				self._logger:warn("Failed to restore script", {
					path = scriptData.path,
					error = error
				})
			end
		end
	end
	
	if self._logger then
		self._logger:info("Snapshot restore completed", {
			restored = restored,
			failed = failed
		})
	end
	
	return true, {
		restored = restored,
		failed = failed
	}
end

-- Toplu script güncelleme
function WorkspaceManager:bulkUpdate(updates)
	local results = {
		success = 0,
		failed = 0,
		errors = {}
	}
	
	for _, update in ipairs(updates) do
		local scriptInstance = update.instance or self:findScriptByPath(update.path)
		
		if scriptInstance then
			local success, error = self:writeScript(scriptInstance, update.source)
			if success then
				results.success = results.success + 1
			else
				results.failed = results.failed + 1
				table.insert(results.errors, {
					path = update.path or getFullPath(scriptInstance),
					error = error
				})
			end
		else
			results.failed = results.failed + 1
			table.insert(results.errors, {
				path = update.path,
				error = "Script not found"
			})
		end
	end
	
	return results
end

-- Service'leri al
function WorkspaceManager:getServices()
	return {
		Workspace = game:GetService("Workspace"),
		ReplicatedStorage = game:GetService("ReplicatedStorage"),
		ServerScriptService = game:GetService("ServerScriptService"),
		StarterPlayer = game:GetService("StarterPlayer"),
		StarterPack = game:GetService("StarterPack"),
		StarterGui = game:GetService("StarterGui")
	}
end

return WorkspaceManager
