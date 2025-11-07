# AI Coder Plugin for Roblox Studio

🤖 **AI-Powered Coding Assistant** - Roblox Studio için yapay zeka destekli profesyonel kodlama asistanı plugin'i.

## 🌟 Özellikler

### ✨ Temel Özellikler
- **Çoklu AI Desteği**: OpenAI GPT-4, Claude 3, Google Gemini entegrasyonu
- **Akıllı Kod Asistanı**: Doğal dil ile kod oluşturma, düzenleme ve debugging
- **Tam Workspace Erişimi**: Tüm scriptlere okuma/yazma/oluşturma/silme yetkisi
- **Kod Önizleme**: AI değişikliklerini uygulamadan önce diff görüntüleme
- **Undo/Redo Sistemi**: İşlem geçmişi ile geri alma/yineleme
- **Güvenlik Katmanı**: Zararlı kod tespiti ve güvenlik kontrolü
- **Modern Arayüz**: Koyu tema, kullanıcı dostu tasarım
- **Çoklu Dil**: Türkçe ve İngilizce arayüz desteği

### 🔒 Güvenlik
- API anahtarları şifrelenmiş olarak saklanır
- Zararlı kod pattern tespiti
- Operasyon rate limiting
- Kritik işlemler için onay mekanizması
- Input sanitization

### 🚀 Gelişmiş Özellikler
- Kod analizi ve karmaşıklık ölçümü
- Workspace bağlam oluşturma
- Otomatik dependency mapping
- İşlem geçmişi ve snapshot'lar
- HTTP request retry logic ile API hatalarını önleme

## 📋 Gereksinimler

- **Roblox Studio** (En son sürüm önerilir)
- **Rojo** (Plugin geliştirme için)
- **Node.js ve npm** (Build scriptleri için)
- **Git** (Versiyon kontrolü için)

### AI API Anahtarları
En az bir AI sağlayıcısından API anahtarı gereklidir:

- **OpenAI**: https://platform.openai.com/api-keys
- **Anthropic Claude**: https://console.anthropic.com/
- **Google Gemini**: https://makersuite.google.com/app/apikey

## 🔧 Kurulum

### 1. Projeyi İndirin
```bash
git clone https://github.com/swxff/roblox-ai-coder-plugin.git
cd roblox-ai-coder-plugin
```

### 2. Rojo'yu Kurun (Eğer yoksa)
```bash
# Cargo ile (Rust gerektirir)
cargo install rojo

# Veya Aftman kullanarak
aftman add rojo-rbx/rojo
```

### 3. Plugin'i Build Edin
```bash
npm run build
```

### 4. Plugin'i Roblox Studio'ya Yükleyin
```bash
npm run install-plugin
```

Alternatif olarak, `plugin.rbxm` dosyasını manuel olarak şu konuma kopyalayın:
```
Windows: %LOCALAPPDATA%\Roblox\Plugins\
macOS: ~/Documents/Roblox/Plugins/
```

## 🎮 Kullanım

### İlk Kurulum
1. Roblox Studio'yu açın
2. "Plugins" sekmesinde "AI Coder" butonuna tıklayın
3. Açılan pencerede "Settings" butonuna basın
4. AI sağlayıcınızı seçin ve API anahtarınızı girin
5. Dil tercihinizi belirleyin (Türkçe/English)

### Temel Kullanım

#### Kod Oluşturma
```
"Bir Part oluşturup kırmızı renge boyayan script yaz"
```

#### Kod Düzenleme
```
"PlayerScript'teki character hızını 50'ye çıkar"
```

#### Kod Analizi
```
"Workspace'deki tüm scriptleri analiz et ve optimizasyon önerileri sun"
```

#### Debugging
```
"MainScript'te neden hata alıyorum?"
```

### Gelişmiş Özellikler

#### Kod Önizleme
AI bir kod değişikliği önerdiğinde:
1. Diff önizlemesi otomatik açılır
2. Değişiklikleri inceleyebilirsiniz
3. "Apply" veya "Reject" ile onaylayın/reddedin

#### İşlem Geçmişi
- Undo/Redo butonları ile önceki işlemlere dönün
- History panelinde tüm işlemleri görüntüleyin

#### Context Sağlama
AI otomatik olarak workspace'inizin yapısını analiz eder ve bağlam oluşturur.

## ⚙️ Yapılandırma

### Konfigürasyon Dosyası
`src/Config.lua` dosyasında tüm ayarları özelleştirebilirsiniz:

```lua
-- API Endpoints
Config.API_ENDPOINTS = {
    OPENAI = "https://api.openai.com/v1/chat/completions",
    CLAUDE = "https://api.anthropic.com/v1/messages",
    GEMINI = "https://generativelanguage.googleapis.com/v1beta/..."
}

-- Rate Limiting
Config.RATE_LIMITS = {
    MAX_REQUESTS_PER_MINUTE = 20,
    REQUEST_TIMEOUT = 60,
    RETRY_ATTEMPTS = 3
}

-- Security
Config.SECURITY = {
    ENCRYPT_API_KEYS = true,
    REQUIRE_CONFIRMATION = true,
    MAX_CODE_SIZE = 500000
}
```

## 🏗️ Mimari

### Proje Yapısı
```
rblx/
├── src/
│   ├── Plugin.lua          # Ana entry point
│   ├── Config.lua          # Global konfigürasyon
│   ├── Utils/              # Yardımcı modüller
│   │   ├── Logger.lua
│   │   ├── Storage.lua
│   │   ├── Encryption.lua
│   │   ├── Localization.lua
│   │   └── HTTPClient.lua
│   ├── Core/               # Çekirdek sistemler
│   │   ├── SecurityManager.lua
│   │   ├── WorkspaceManager.lua
│   │   ├── CodeAnalyzer.lua
│   │   ├── DiffEngine.lua
│   │   └── HistoryManager.lua
│   ├── AI/                 # AI entegrasyonları
│   │   ├── PromptBuilder.lua
│   │   ├── ResponseParser.lua
│   │   ├── OpenAIProvider.lua
│   │   ├── ClaudeProvider.lua
│   │   ├── GeminiProvider.lua
│   │   └── APIManager.lua
│   └── UI/                 # Kullanıcı arayüzü
│       └── Themes.lua
├── assets/
│   └── locales/            # Çeviri dosyaları
│       ├── en.json
│       └── tr.json
├── tests/                  # Test dosyaları
├── default.project.json    # Rojo config
├── package.json
└── README.md
```

### Akış Diyagramı
```
User Input → PromptBuilder → APIManager → AI Provider
                                              ↓
                                      ResponseParser
                                              ↓
                                        DiffEngine
                                              ↓
                                      PreviewPanel
                                              ↓
                                  WorkspaceManager → Script Update
                                              ↓
                                     HistoryManager
```

## 🔐 Güvenlik

### API Anahtarı Güvenliği
- Tüm API anahtarları XOR + Base64 şifreleme ile korunur
- Anahtarlar PluginSettings'de güvenli şekilde saklanır
- Her kullanıcı için benzersiz salt oluşturulur

### Kod Güvenliği
Plugin şu zararlı pattern'leri tespit eder:
- `require()` ile HTTP istekleri
- `loadstring()` kullanımı
- `getfenv()` / `setfenv()` erişimi

### Rate Limiting
- Dakikada maksimum 20 istek
- Retry logic ile 3 deneme
- Timeout koruması (60 saniye)

## 🛠️ Geliştirme

### Development Mode
```bash
# Watch mode ile geliştirme
npm run watch

# Build ve install
npm run dev

# Temizleme
npm run clean
```

### Debug Modu
`src/Config.lua` dosyasında:
```lua
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG",
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

### Test
```bash
# Test suite çalıştırma
npm test
```

## 📝 Sık Sorulan Sorular

### API Anahtarım Çalışmıyor
- API anahtarının doğru formatta olduğundan emin olun
- OpenAI: `sk-` ile başlamalı
- Claude: `sk-ant-` ile başlamalı
- Gemini: Alfanumerik karakter string'i
- API limitinizi kontrol edin

### Plugin Yüklenmiyor
- Roblox Studio'yu yeniden başlatın
- `%LOCALAPPDATA%\Roblox\Plugins\` yolunu kontrol edin
- Plugin dosyasının `.rbxm` uzantılı olduğundan emin olun

### AI Yanıt Vermiyor
- API anahtarınızı kontrol edin
- İnternet bağlantınızı kontrol edin
- Rate limit'e takılmış olabilirsiniz (1 dakika bekleyin)
- Debug modunu açıp logları inceleyin

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

MIT License - Detaylar için `LICENSE` dosyasına bakın.

## 👨‍💻 Geliştirici

**swxff**
- GitHub: [@swxff](https://github.com/swxff)

## 🙏 Teşekkürler

- OpenAI, Anthropic ve Google AI ekiplerine
- Roblox ve Rojo topluluğuna
- Tüm katkıda bulunanlara

## 📞 Destek

Sorunlarınız için:
- GitHub Issues: https://github.com/swxff/roblox-ai-coder-plugin/issues
- Dokümantasyon: Bu README dosyası

---

⭐ Beğendiyseniz yıldız vermeyi unutmayın!
