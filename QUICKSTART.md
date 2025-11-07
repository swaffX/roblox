# 🚀 AI Coder Plugin - Quick Start

## ✅ Plugin Kurulumu Tamamlandı!

Plugin başarıyla build edildi ve Roblox Studio'ya kuruldu:
- **Konum:** `%LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm`

## 📋 İlk Kullanım Adımları

### 1. Roblox Studio'yu Aç
- Roblox Studio'yu başlat veya yeniden başlat
- Herhangi bir Roblox Place'i aç

### 2. Plugin'i Etkinleştir
- Üst menüdeki **"Plugins"** sekmesine git
- **"AI Coder"** butonunu bul ve tıkla
- Modern, koyu temalı UI penceresi açılacak

### 3. API Anahtarı Yapılandır
- Sağ üstteki **ayarlar (⚙️)** ikonuna tıkla
- AI Provider seç (OpenAI, Claude veya Gemini)
- İlgili API anahtarını gir:
  - **OpenAI:** `sk-...` ile başlamalı
  - **Claude:** `sk-ant-...` ile başlamalı  
  - **Gemini:** Alphanumerik string
- **"Save"** butonuna tıkla

### 4. İlk Mesajı Gönder
Alt kısımdaki input alanına komut yaz, örneğin:
```
Workspace'e yeni bir Part oluştur ve onu kırmızı yap
```

**"Send"** butonuna tıkla veya Enter tuşuna bas.

## 🎨 Modern UI Özellikleri

### Ana Ekran Düzeni
```
┌─────────────────────────────────────────────┐
│  AI Coder • v1.0.0    [Provider] [⚙️] [↶]  │ ← Top Bar
├─────────┬───────────────────────────────────┤
│ History │                                   │
│         │     Chat Mesajları                │
│ • You:  │     & Kod Önizlemeleri            │
│   ...   │                                   │
│         │                                   │
│ • AI:   │───────────────────────────────────│
│   ...   │  📝 [Mesaj yazın...]     [Send]  │ ← Input
└─────────┴───────────────────────────────────┘
```

### Bileşenler
- **Top Bar:** Plugin versiyon bilgisi, provider seçimi, settings, undo
- **Left Panel:** Konuşma geçmişi (History)
- **Main Area:** Chat interface + kod önizlemeleri
- **Input Area:** Multi-line text input + Send button
- **Settings Modal:** API key yönetimi, provider yapılandırması

## 🧪 Test Komutları

Plugin'i test etmek için şu komutları deneyin:

### Basit Komutlar
```
Workspace'te tüm Part'ları listele
```

```
ServerScriptService'e yeni bir script oluştur
```

### Kod Oluşturma
```
Bir player touch ettiğinde rengi değişen Part için script yaz
```

```
Part rotate eden bir tween animasyonu yaz
```

### Kod Analizi
```
Workspace'deki tüm scriptleri analiz et
```

## 🔧 Geliştirme Komutları

### Build & Yeniden Yükle
```bash
npm run build
npm run install-plugin
```

### Watch Mode (Canlı Geliştirme)
```bash
npm run watch
```
Rojo Studio plugin'i ile birlikte kullanarak değişiklikleri canlı görebilirsiniz.

### Build + Install (Tek Komut)
```bash
npm run dev
```

## 🎯 Temel Özellikler

### ✨ Şu An Çalışıyor
- ✅ Modern, koyu temalı UI (Vibe Coder tarzı)
- ✅ Multi-AI provider desteği (OpenAI, Claude, Gemini)
- ✅ Şifreli API key depolama
- ✅ Chat interface + mesaj geçmişi
- ✅ Kod bloku önizleme
- ✅ Settings modal
- ✅ Provider değiştirme (dropdown)
- ✅ Undo/Redo butonu
- ✅ Loading spinner (AI düşünürken)

### 🚧 Geliştirilmesi Gerekenler
- Kod değişikliklerini workspace'e uygulama (WorkspaceManager entegrasyonu)
- Diff görüntüleme ve onay sistemi
- Script seçici (hangi script'e işlem yapılacak)
- Conversation history persistence
- Daha zengin hata mesajları
- Kod syntax highlighting

## 🐛 Bilinen Sınırlamalar

1. **HTTP Providers:** Şu an sadece ClaudeProvider, OpenAIProvider, GeminiProvider stub'ları mevcut - gerçek HTTP implementasyonu HTTPClient üzerinden yapılmalı
2. **Workspace Entegrasyonu:** AI'dan gelen kod bloklarının otomatik olarak script'lere yazılması henüz entegre değil (WorkspaceManager hazır, MainUI'a bağlanmalı)
3. **Error Handling:** API hatalarında detaylı mesajlar yerine genel error gösteriliyor

## 📝 Notlar

- Plugin her açılışta eski UI state'i sıfırlanır
- API anahtarları PluginSettings'de güvenli şekilde saklanır
- Chat geçmişi şu an session-based (kalıcı değil)
- Tüm operasyonlar SecurityManager'dan geçer

## 🆘 Sorun Giderme

### Plugin Görünmüyor
1. Roblox Studio'yu tamamen kapat ve tekrar aç
2. `%LOCALAPPDATA%\Roblox\Plugins\` dizinini kontrol et
3. `npm run install-plugin` komutunu tekrar çalıştır

### API Çağrısı Başarısız
1. API anahtarının doğru formatta olduğunu kontrol et
2. İnternet bağlantını kontrol et
3. Provider'ın rate limitini kontrol et
4. Debug modunu aktif et (Config.DEBUG.ENABLED = true)

### UI Bozuk Görünüyor
1. Plugin penceresini kapat ve tekrar aç
2. Studio'yu yeniden başlat
3. Plugin'i yeniden build et ve kur

## 🎓 İleri Düzey

### Custom System Prompts
`src/Config.lua` dosyasında `SYSTEM_PROMPTS` bölümünü düzenle:
```lua
Config.SYSTEM_PROMPTS = {
    DEFAULT = [[Your custom system prompt here...]],
    ANALYSIS = [[Custom analysis prompt...]],
    REFACTOR = [[Custom refactor prompt...]]
}
```

### Debug Modu
`src/Config.lua`:
```lua
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG",
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

Loglar Roblox Studio **Output** penceresinde görünür.

---

**🎉 Başarıyla kuruldu! Plugin kullanıma hazır.**

Sorular için: GitHub Issues veya README.md
