--[[
	HistoryManager - Undo/Redo Sistemi
	
	Stack-based history management ile tüm operasyonları takip eder.
]]

local HistoryManager = {}
HistoryManager.__index = HistoryManager

function HistoryManager.new(workspaceManager, storage, logger)
	local self = setmetatable({}, HistoryManager)
	
	self._workspace = workspaceManager
	self._storage = storage
	self._logger = logger
	
	self._undoStack = {}
	self._redoStack = {}
	self._maxHistory = 100
	
	-- Persistent history'yi yükle
	self:_loadHistory()
	
	return self
end

-- Operation tiplerini tanımla
local OperationType = {
	CREATE = "create",
	UPDATE = "update",
	DELETE = "delete",
	MOVE = "move"
}

-- History'yi storage'a kaydet
function HistoryManager:_saveHistory()
	if self._storage then
		local historyData = {}
		for _, op in ipairs(self._undoStack) do
			table.insert(historyData, {
				type = op.type,
				timestamp = op.timestamp,
				description = op.description
			})
		end
		self._storage:saveOperationHistory(historyData)
	end
end

-- History'yi storage'dan yükle
function HistoryManager:_loadHistory()
	if self._storage then
		local historyData = self._storage:getOperationHistory()
		-- Not: Sadece metadata yükleniyor, actual operations yeniden oluşturulamaz
	end
end

-- Operasyon kaydet
function HistoryManager:recordOperation(operationType, data)
	local operation = {
		type = operationType,
		timestamp = tick(),
		description = data.description or operationType,
		data = data
	}
	
	table.insert(self._undoStack, operation)
	
	-- Max history limitini kontrol et
	if #self._undoStack > self._maxHistory then
		table.remove(self._undoStack, 1)
	end
	
	-- Redo stack'i temizle
	self._redoStack = {}
	
	self:_saveHistory()
	
	if self._logger then
		self._logger:info("Operation recorded", {
			type = operationType,
			description = operation.description
		})
	end
end

-- Script güncelleme operasyonu kaydet
function HistoryManager:recordUpdate(scriptInstance, oldSource, newSource)
	local data = {
		description = string.format("Updated %s", scriptInstance.Name),
		scriptPath = self._workspace and self._workspace:getScriptMetadata(scriptInstance).path or scriptInstance.Name,
		scriptInstance = scriptInstance,
		oldSource = oldSource,
		newSource = newSource
	}
	
	self:recordOperation(OperationType.UPDATE, data)
end

-- Script oluşturma operasyonu kaydet
function HistoryManager:recordCreate(scriptInstance)
	local data = {
		description = string.format("Created %s", scriptInstance.Name),
		scriptPath = self._workspace and self._workspace:getScriptMetadata(scriptInstance).path or scriptInstance.Name,
		scriptInstance = scriptInstance,
		source = self._workspace and self._workspace:readScript(scriptInstance) or ""
	}
	
	self:recordOperation(OperationType.CREATE, data)
end

-- Script silme operasyonu kaydet
function HistoryManager:recordDelete(scriptInstance, source)
	local data = {
		description = string.format("Deleted %s", scriptInstance.Name),
		scriptPath = self._workspace and self._workspace:getScriptMetadata(scriptInstance).path or scriptInstance.Name,
		scriptName = scriptInstance.Name,
		scriptType = scriptInstance.ClassName,
		scriptParent = scriptInstance.Parent,
		source = source
	}
	
	self:recordOperation(OperationType.DELETE, data)
end

-- Undo
function HistoryManager:undo()
	if #self._undoStack == 0 then
		return false, "Nothing to undo"
	end
	
	local operation = table.remove(self._undoStack)
	table.insert(self._redoStack, operation)
	
	local success, error = self:_reverseOperation(operation)
	
	if success then
		self:_saveHistory()
		if self._logger then
			self._logger:info("Undo successful", { description = operation.description })
		end
	else
		-- Başarısız olursa geri ekle
		table.insert(self._undoStack, operation)
		table.remove(self._redoStack)
	end
	
	return success, error
end

-- Redo
function HistoryManager:redo()
	if #self._redoStack == 0 then
		return false, "Nothing to redo"
	end
	
	local operation = table.remove(self._redoStack)
	table.insert(self._undoStack, operation)
	
	local success, error = self:_applyOperation(operation)
	
	if success then
		self:_saveHistory()
		if self._logger then
			self._logger:info("Redo successful", { description = operation.description })
		end
	else
		-- Başarısız olursa geri ekle
		table.insert(self._redoStack, operation)
		table.remove(self._undoStack)
	end
	
	return success, error
end

-- Operasyonu tersine çevir
function HistoryManager:_reverseOperation(operation)
	if not self._workspace then
		return false, "Workspace manager not available"
	end
	
	if operation.type == OperationType.UPDATE then
		-- Eski source'a geri dön
		return self._workspace:writeScript(operation.data.scriptInstance, operation.data.oldSource)
	elseif operation.type == OperationType.CREATE then
		-- Oluşturulan script'i sil
		return self._workspace:deleteScript(operation.data.scriptInstance)
	elseif operation.type == OperationType.DELETE then
		-- Silinen script'i yeniden oluştur
		local script = self._workspace:createScript(
			operation.data.scriptParent,
			operation.data.scriptName,
			operation.data.scriptType,
			operation.data.source
		)
		return script ~= nil, script and nil or "Failed to recreate script"
	end
	
	return false, "Unknown operation type"
end

-- Operasyonu uygula (redo için)
function HistoryManager:_applyOperation(operation)
	if not self._workspace then
		return false, "Workspace manager not available"
	end
	
	if operation.type == OperationType.UPDATE then
		-- Yeni source'u uygula
		return self._workspace:writeScript(operation.data.scriptInstance, operation.data.newSource)
	elseif operation.type == OperationType.CREATE then
		-- Script'i yeniden oluştur (zaten var, skip)
		return true
	elseif operation.type == OperationType.DELETE then
		-- Script'i tekrar sil
		return self._workspace:deleteScript(operation.data.scriptInstance)
	end
	
	return false, "Unknown operation type"
end

-- History'yi temizle
function HistoryManager:clear()
	self._undoStack = {}
	self._redoStack = {}
	self:_saveHistory()
	
	if self._logger then
		self._logger:info("History cleared")
	end
end

-- History bilgisi al
function HistoryManager:getHistory()
	return {
		undoCount = #self._undoStack,
		redoCount = #self._redoStack,
		operations = self._undoStack
	}
end

-- Undo/Redo durumu
function HistoryManager:canUndo()
	return #self._undoStack > 0
end

function HistoryManager:canRedo()
	return #self._redoStack > 0
end

return HistoryManager
