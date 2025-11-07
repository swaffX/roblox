--[[
	DiffEngine - Kod Karşılaştırma Motoru
	
	İki kod versiyonu arasında diff oluşturur.
	Line-by-line comparison ve UI için formatlanmış output.
]]

local DiffEngine = {}

-- Diff tipi enum
local DiffType = {
	ADDED = "added",
	REMOVED = "removed",
	MODIFIED = "modified",
	UNCHANGED = "unchanged"
}

-- Satırları array'e böl
local function splitLines(text)
	local lines = {}
	for line in string.gmatch(text .. "\n", "(.-)\n") do
		table.insert(lines, line)
	end
	return lines
end

-- İki satır benzer mi?
local function areSimilar(line1, line2, threshold)
	threshold = threshold or 0.8
	
	if line1 == line2 then
		return true
	end
	
	-- Trim whitespace
	local trimmed1 = string.gsub(line1, "^%s+", "")
	local trimmed2 = string.gsub(line2, "^%s+", "")
	
	if trimmed1 == trimmed2 then
		return true
	end
	
	-- Basit similarity check
	local len1, len2 = #trimmed1, #trimmed2
	if len1 == 0 and len2 == 0 then
		return true
	end
	
	local maxLen = math.max(len1, len2)
	if maxLen == 0 then
		return true
	end
	
	local minLen = math.min(len1, len2)
	local similarity = minLen / maxLen
	
	return similarity >= threshold
end

-- Basit diff algoritması (Myers diff'in basitleştirilmiş versiyonu)
function DiffEngine.computeDiff(oldText, newText)
	local oldLines = splitLines(oldText or "")
	local newLines = splitLines(newText or "")
	
	local diff = {}
	local oldIdx, newIdx = 1, 1
	
	while oldIdx <= #oldLines or newIdx <= #newLines do
		if oldIdx > #oldLines then
			-- Sadece yeni satırlar kaldı
			table.insert(diff, {
				type = DiffType.ADDED,
				oldLineNum = nil,
				newLineNum = newIdx,
				content = newLines[newIdx]
			})
			newIdx = newIdx + 1
		elseif newIdx > #newLines then
			-- Sadece eski satırlar kaldı
			table.insert(diff, {
				type = DiffType.REMOVED,
				oldLineNum = oldIdx,
				newLineNum = nil,
				content = oldLines[oldIdx]
			})
			oldIdx = oldIdx + 1
		elseif oldLines[oldIdx] == newLines[newIdx] then
			-- Satırlar aynı
			table.insert(diff, {
				type = DiffType.UNCHANGED,
				oldLineNum = oldIdx,
				newLineNum = newIdx,
				content = oldLines[oldIdx]
			})
			oldIdx = oldIdx + 1
			newIdx = newIdx + 1
		elseif areSimilar(oldLines[oldIdx], newLines[newIdx], 0.7) then
			-- Satırlar değiştirilmiş
			table.insert(diff, {
				type = DiffType.MODIFIED,
				oldLineNum = oldIdx,
				newLineNum = newIdx,
				oldContent = oldLines[oldIdx],
				content = newLines[newIdx]
			})
			oldIdx = oldIdx + 1
			newIdx = newIdx + 1
		else
			-- Satır eklendi veya silindi, hangisi olduğunu anlamaya çalış
			local nextOldMatchesNew = oldIdx + 1 <= #oldLines and oldLines[oldIdx + 1] == newLines[newIdx]
			local nextNewMatchesOld = newIdx + 1 <= #newLines and newLines[newIdx + 1] == oldLines[oldIdx]
			
			if nextOldMatchesNew then
				-- Eski satır silindi
				table.insert(diff, {
					type = DiffType.REMOVED,
					oldLineNum = oldIdx,
					newLineNum = nil,
					content = oldLines[oldIdx]
				})
				oldIdx = oldIdx + 1
			elseif nextNewMatchesOld then
				-- Yeni satır eklendi
				table.insert(diff, {
					type = DiffType.ADDED,
					oldLineNum = nil,
					newLineNum = newIdx,
					content = newLines[newIdx]
				})
				newIdx = newIdx + 1
			else
				-- Değiştirilmiş olarak işaretle
				table.insert(diff, {
					type = DiffType.MODIFIED,
					oldLineNum = oldIdx,
					newLineNum = newIdx,
					oldContent = oldLines[oldIdx],
					content = newLines[newIdx]
				})
				oldIdx = oldIdx + 1
				newIdx = newIdx + 1
			end
		end
	end
	
	return diff
end

-- Diff'i text formatında oluştur
function DiffEngine.formatDiff(diff)
	local lines = {}
	
	for _, change in ipairs(diff) do
		if change.type == DiffType.ADDED then
			table.insert(lines, string.format("+ %s", change.content))
		elseif change.type == DiffType.REMOVED then
			table.insert(lines, string.format("- %s", change.content))
		elseif change.type == DiffType.MODIFIED then
			table.insert(lines, string.format("- %s", change.oldContent))
			table.insert(lines, string.format("+ %s", change.content))
		else
			table.insert(lines, string.format("  %s", change.content))
		end
	end
	
	return table.concat(lines, "\n")
end

-- Diff istatistikleri
function DiffEngine.getStats(diff)
	local stats = {
		added = 0,
		removed = 0,
		modified = 0,
		unchanged = 0
	}
	
	for _, change in ipairs(diff) do
		if change.type == DiffType.ADDED then
			stats.added = stats.added + 1
		elseif change.type == DiffType.REMOVED then
			stats.removed = stats.removed + 1
		elseif change.type == DiffType.MODIFIED then
			stats.modified = stats.modified + 1
		else
			stats.unchanged = stats.unchanged + 1
		end
	end
	
	return stats
end

-- Patch oluştur (apply edilebilir format)
function DiffEngine.createPatch(scriptPath, oldText, newText)
	local diff = DiffEngine.computeDiff(oldText, newText)
	local stats = DiffEngine.getStats(diff)
	
	return {
		path = scriptPath,
		oldText = oldText,
		newText = newText,
		diff = diff,
		stats = stats,
		timestamp = tick()
	}
end

-- Patch'i uygula
function DiffEngine.applyPatch(patch)
	-- Basit implementasyon: sadece yeni text'i döndür
	return patch.newText
end

return DiffEngine
