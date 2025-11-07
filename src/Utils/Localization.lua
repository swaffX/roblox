--[[
	Localization - Çoklu Dil Desteği
	
	i18n sistemi ile Türkçe ve İngilizce dil desteği sağlar.
	Placeholder replacement ile dinamik çeviriler yapar.
]]

local Config = require(script.Parent.Parent.Config)

local Localization = {}
Localization.__index = Localization

-- Yüklenen dil dosyaları
local translations = {}

-- Varsayılan çeviriler (fallback)
local defaultTranslations = {
	en = {
		-- Genel
		["app.title"] = "AI Coder Assistant",
		["app.description"] = "AI-powered coding assistant for Roblox Studio",
		
		-- Butonlar
		["button.send"] = "Send",
		["button.clear"] = "Clear",
		["button.settings"] = "Settings",
		["button.save"] = "Save",
		["button.cancel"] = "Cancel",
		["button.apply"] = "Apply",
		["button.reject"] = "Reject",
		["button.undo"] = "Undo",
		["button.redo"] = "Redo",
		["button.close"] = "Close",
		
		-- Chat
		["chat.placeholder"] = "Type your message here...",
		["chat.thinking"] = "AI is thinking...",
		["chat.error"] = "Error: {error}",
		["chat.welcome"] = "Hello! I'm your AI coding assistant. How can I help you today?",
		
		-- Ayarlar
		["settings.title"] = "Settings",
		["settings.provider"] = "AI Provider",
		["settings.model"] = "Model",
		["settings.api_key"] = "API Key",
		["settings.language"] = "Language",
		["settings.api_key_placeholder"] = "Enter your API key",
		["settings.api_key_saved"] = "API key saved successfully",
		["settings.api_key_invalid"] = "Invalid API key format",
		["settings.api_key_missing"] = "Please enter an API key for {provider}",
		
		-- Önizleme
		["preview.title"] = "Code Preview",
		["preview.changes"] = "Changes to {file}",
		["preview.confirm"] = "Do you want to apply these changes?",
		["preview.applied"] = "Changes applied successfully",
		["preview.rejected"] = "Changes rejected",
		
		-- Geçmiş
		["history.title"] = "Operation History",
		["history.empty"] = "No operations yet",
		["history.clear"] = "Clear History",
		["history.operation"] = "Operation #{number}",
		
		-- Hatalar
		["error.api_call_failed"] = "API call failed: {error}",
		["error.no_api_key"] = "No API key configured for {provider}",
		["error.network"] = "Network error: {error}",
		["error.timeout"] = "Request timed out",
		["error.invalid_response"] = "Invalid response from AI",
		
		-- Başarı mesajları
		["success.script_created"] = "Script created: {name}",
		["success.script_updated"] = "Script updated: {name}",
		["success.script_deleted"] = "Script deleted: {name}",
		
		-- Onay mesajları
		["confirm.delete"] = "Are you sure you want to delete {name}?",
		["confirm.clear_history"] = "Are you sure you want to clear all history?",
		["confirm.apply_changes"] = "Apply changes to {count} file(s)?",
	},
	
	tr = {
		-- Genel
		["app.title"] = "AI Kod Asistanı",
		["app.description"] = "Roblox Studio için yapay zeka destekli kodlama asistanı",
		
		-- Butonlar
		["button.send"] = "Gönder",
		["button.clear"] = "Temizle",
		["button.settings"] = "Ayarlar",
		["button.save"] = "Kaydet",
		["button.cancel"] = "İptal",
		["button.apply"] = "Uygula",
		["button.reject"] = "Reddet",
		["button.undo"] = "Geri Al",
		["button.redo"] = "Yinele",
		["button.close"] = "Kapat",
		
		-- Chat
		["chat.placeholder"] = "Mesajınızı buraya yazın...",
		["chat.thinking"] = "AI düşünüyor...",
		["chat.error"] = "Hata: {error}",
		["chat.welcome"] = "Merhaba! Ben senin AI kodlama asistanınım. Bugün sana nasıl yardımcı olabilirim?",
		
		-- Ayarlar
		["settings.title"] = "Ayarlar",
		["settings.provider"] = "AI Sağlayıcı",
		["settings.model"] = "Model",
		["settings.api_key"] = "API Anahtarı",
		["settings.language"] = "Dil",
		["settings.api_key_placeholder"] = "API anahtarınızı girin",
		["settings.api_key_saved"] = "API anahtarı başarıyla kaydedildi",
		["settings.api_key_invalid"] = "Geçersiz API anahtarı formatı",
		["settings.api_key_missing"] = "Lütfen {provider} için bir API anahtarı girin",
		
		-- Önizleme
		["preview.title"] = "Kod Önizleme",
		["preview.changes"] = "{file} dosyasındaki değişiklikler",
		["preview.confirm"] = "Bu değişiklikleri uygulamak istiyor musunuz?",
		["preview.applied"] = "Değişiklikler başarıyla uygulandı",
		["preview.rejected"] = "Değişiklikler reddedildi",
		
		-- Geçmiş
		["history.title"] = "İşlem Geçmişi",
		["history.empty"] = "Henüz işlem yok",
		["history.clear"] = "Geçmişi Temizle",
		["history.operation"] = "İşlem #{number}",
		
		-- Hatalar
		["error.api_call_failed"] = "API çağrısı başarısız: {error}",
		["error.no_api_key"] = "{provider} için API anahtarı yapılandırılmamış",
		["error.network"] = "Ağ hatası: {error}",
		["error.timeout"] = "İstek zaman aşımına uğradı",
		["error.invalid_response"] = "AI'dan geçersiz yanıt",
		
		-- Başarı mesajları
		["success.script_created"] = "Script oluşturuldu: {name}",
		["success.script_updated"] = "Script güncellendi: {name}",
		["success.script_deleted"] = "Script silindi: {name}",
		
		-- Onay mesajları
		["confirm.delete"] = "{name} dosyasını silmek istediğinizden emin misiniz?",
		["confirm.clear_history"] = "Tüm geçmişi temizlemek istediğinizden emin misiniz?",
		["confirm.apply_changes"] = "{count} dosyaya değişiklikler uygulanacak. Onaylıyor musunuz?",
	}
}

-- Yeni localization instance oluştur
function Localization.new(storage)
	local self = setmetatable({}, Localization)
	
	self._storage = storage
	self._currentLang = storage and storage:getLanguage() or Config.DEFAULT_LANGUAGE
	
	-- Varsayılan çevirileri yükle
	translations = defaultTranslations
	
	return self
end

-- Dil değiştir
function Localization:setLanguage(lang)
	if not translations[lang] then
		warn("Language not supported:", lang)
		return false
	end
	
	self._currentLang = lang
	
	if self._storage then
		self._storage:setLanguage(lang)
	end
	
	return true
end

-- Mevcut dili al
function Localization:getLanguage()
	return self._currentLang
end

-- Desteklenen dilleri al
function Localization:getSupportedLanguages()
	return Config.SUPPORTED_LANGUAGES
end

-- Placeholder'ları değiştir
local function replacePlaceholders(text, params)
	if not params then
		return text
	end
	
	for key, value in pairs(params) do
		text = string.gsub(text, "{" .. key .. "}", tostring(value))
	end
	
	return text
end

-- Çeviri al
function Localization:get(key, params)
	local langData = translations[self._currentLang]
	
	if not langData then
		langData = translations[Config.DEFAULT_LANGUAGE]
	end
	
	local text = langData[key]
	
	if not text then
		-- Fallback to English
		if self._currentLang ~= "en" then
			text = translations["en"][key]
		end
		
		-- Eğer hala bulunamadıysa key'i döndür
		if not text then
			warn("Translation not found:", key)
			return key
		end
	end
	
	return replacePlaceholders(text, params)
end

-- Kısa kullanım için alias
function Localization:t(key, params)
	return self:get(key, params)
end

-- Çeviri ekle/güncelle (runtime'da)
function Localization:addTranslation(lang, key, value)
	if not translations[lang] then
		translations[lang] = {}
	end
	
	translations[lang][key] = value
end

-- Toplu çeviri ekle
function Localization:addTranslations(lang, data)
	if not translations[lang] then
		translations[lang] = {}
	end
	
	for key, value in pairs(data) do
		translations[lang][key] = value
	end
end

-- JSON dosyasından çeviri yükle
function Localization:loadFromJSON(lang, jsonData)
	local HttpService = game:GetService("HttpService")
	
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(jsonData)
	end)
	
	if not success then
		warn("Failed to load translations for", lang, ":", decoded)
		return false
	end
	
	self:addTranslations(lang, decoded)
	return true
end

return Localization
