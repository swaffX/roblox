# 🚀 Ekip İçin Kurulum Rehberi - Neurovia AI Coder Plugin

## 📋 İçindekiler
1. [Ön Gereksinimler](#ön-gereksinimler)
2. [Projeyi Klonlama](#projeyi-klonlama)
3. [Bağımlılıkları Kurma](#bağımlılıkları-kurma)
4. [Plugin'i Build Etme](#plugini-build-etme)
5. [Roblox Studio'ya Entegre Etme](#roblox-studioya-entegre-etme)
6. [Warp ile Geliştirme](#warp-ile-geliştirme)
7. [Git Workflow](#git-workflow)
8. [Sorun Giderme](#sorun-giderme)

---

## 🎯 Ön Gereksinimler

### 1. Git Kurulumu
```powershell
# Git kurulu mu kontrol et
git --version

# Eğer yoksa: https://git-scm.com/downloads adresinden indir
```

### 2. Node.js Kurulumu
```powershell
# Node.js kurulu mu kontrol et
node --version
npm --version

# Eğer yoksa: https://nodejs.org/ adresinden LTS sürümünü indir
```

### 3. Rojo Kurulumu
```powershell
# Rojo kurulu mu kontrol et
rojo --version

# Eğer yoksa:
# 1. https://github.com/rojo-rbx/rojo/releases adresinden en son sürümü indir
# 2. rojo.exe dosyasını C:\rojo\ gibi bir klasöre koy
# 3. PATH'e ekle veya proje klasörüne kopyala
```

**PATH'e Ekleme (Windows):**
1. Windows + R → `sysdm.cpl` yaz
2. Advanced → Environment Variables
3. System Variables → Path → Edit
4. New → `C:\rojo\` ekle (veya rojo.exe'nin bulunduğu klasör)
5. OK → OK → OK
6. PowerShell'i yeniden başlat

### 4. Roblox Studio Kurulumu
```powershell
# Roblox Studio kurulu olmalı
# https://www.roblox.com/create adresinden indir
```

### 5. Warp Terminal (Opsiyonel ama Önerilen)
```powershell
# https://www.warp.dev/ adresinden indir
# Modern, AI destekli terminal
```

---

## 📥 Projeyi Klonlama

### Adım 1: Repo URL'sini Al
```powershell
# GitHub repo URL'si (örnek):
# https://github.com/swxff/neurovia-roblox.git
```

### Adım 2: Projeyi Klonla
```powershell
# İstediğin klasöre git
cd C:\Users\[KULLANICI_ADIN]\Desktop

# Projeyi klonla
git clone https://github.com/swxff/neurovia-roblox.git rblx

# Proje klasörüne gir
cd rblx

# Dosyaları kontrol et
ls
```

**Beklenen Çıktı:**
```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----                                            src
d-----                                            assets
d-----                                            tests
-a----                                       9985 00_BAŞLA_BURADAN.md
-a----                                       3656 README.md
-a----                                       1004 package.json
-a----                                        387 default.project.json
...
```

### Adım 3: Branch Kontrolü
```powershell
# Hangi branch'tesin?
git branch

# Main branch'e geç
git checkout main

# Son değişiklikleri çek
git pull origin main
```

---

## 🔧 Bağımlılıkları Kurma

### Node.js Bağımlılıkları
```powershell
# package.json'daki script'leri kullanabilmek için
# (Aslında dış bağımlılık yok, ama npm script'leri çalışacak)
npm install
```

**Not:** Bu proje dış Node.js kütüphanesi kullanmıyor, sadece build script'leri için npm kullanılıyor.

---

## 🏗️ Plugin'i Build Etme

### Adım 1: Build Komutu
```powershell
# Plugin'i build et
npm run build
```

**Bu komut şunları yapar:**
- `default.project.json`'daki yapılandırmayı okur
- `src/` klasöründeki tüm Lua dosyalarını toplar
- `plugin.rbxm` dosyası oluşturur

**Başarılı Çıktı:**
```
> roblox-ai-coder-plugin@1.0.0 build
> rojo build default.project.json -o plugin.rbxm

Built plugin.rbxm
```

### Adım 2: Build Dosyasını Kontrol Et
```powershell
# plugin.rbxm dosyası oluştu mu?
Test-Path .\plugin.rbxm

# Dosya boyutunu gör
(Get-Item .\plugin.rbxm).Length
```

**Beklenen:** `True` ve yaklaşık 40-50 KB boyut

---

## 🎮 Roblox Studio'ya Entegre Etme

### Yöntem 1: Otomatik Kurulum (Önerilen)
```powershell
# Plugin'i otomatik olarak Roblox Studio'ya kur
npm run install-plugin
```

**Bu komut şunları yapar:**
1. `%LOCALAPPDATA%\Roblox\Plugins\` klasörünü oluşturur (yoksa)
2. `plugin.rbxm` dosyasını `AI-Coder-Plugin.rbxm` olarak kopyalar
3. Eski versiyonun üzerine yazar

**Başarılı Çıktı:**
```
> roblox-ai-coder-plugin@1.0.0 install-plugin
> powershell -Command "New-Item ..."

    Directory: C:\Users\[USER]\AppData\Local\Roblox\Plugins

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----                                      46322 AI-Coder-Plugin.rbxm
```

### Yöntem 2: Manuel Kurulum
```powershell
# 1. Plugin dosyasını kopyala
Copy-Item .\plugin.rbxm -Destination "$env:LOCALAPPDATA\Roblox\Plugins\AI-Coder-Plugin.rbxm" -Force

# 2. Kurulumu kontrol et
Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\AI-Coder-Plugin.rbxm"
```

### Adım 3: Roblox Studio'yu Başlat
1. **Roblox Studio'yu tamamen kapat** (çalışıyorsa)
2. Roblox Studio'yu yeniden başlat
3. Herhangi bir Place aç (veya yeni bir place oluştur)

### Adım 4: Plugin'i Etkinleştir
1. Üst menüde **"Plugins"** sekmesine tıkla
2. **"AI Coder"** veya **"Neurovia"** butonunu bul
3. Butona tıkla
4. Koyu temalı bir UI penceresi açılmalı

**Eğer buton görünmüyorsa:**
```powershell
# Plugin'in yüklü olduğunu kontrol et
Get-Item "$env:LOCALAPPDATA\Roblox\Plugins\*.rbxm"

# Roblox Studio'yu tamamen kapat ve tekrar aç
```

### Adım 5: API Key Yapılandırması
1. Plugin penceresinde sağ üstteki **⚙️ (Settings)** ikonuna tıkla
2. **AI Provider** seç:
   - **Gemini** (Ücretsiz başlangıç için önerilen)
   - Claude
   - OpenAI
3. **API Key** gir:
   - **Gemini:** https://makersuite.google.com/app/apikey
   - **OpenAI:** https://platform.openai.com/api-keys
   - **Claude:** https://console.anthropic.com/
4. **Save** butonuna tıkla

### Adım 6: İlk Test
Plugin'e şunu yaz:
```
Workspace'e kırmızı bir Part oluştur
```

**Beklenen Sonuç:**
- AI yanıt verir
- Workspace'e kırmızı bir Part eklenir
- Chat'te kod önizlemesi görünür

---

## 🌀 Warp ile Geliştirme

### Warp Nedir?
Warp, modern bir terminal uygulamasıdır. Özellikler:
- AI destekli komut önerileri
- Komut geçmişi arama (Ctrl+R)
- Otomatik tamamlama
- Modern UI

### Warp Kurulumu
1. https://www.warp.dev/ adresinden indir
2. Kur ve aç
3. PowerShell'i seç (varsayılan shell)

### Warp'ta Proje Açma
```powershell
# Proje klasörüne git
cd C:\Users\[KULLANICI_ADIN]\Desktop\rblx

# Warp'a proje klasörünü tanıt
# Artık Warp seni bu klasörde hatırlayacak
```

### Warp'ta Yararlı Komutlar

#### 1. Hızlı Build & Install
```powershell
# Tek komutta build + kur
npm run dev
```

#### 2. Dosya Arama
```powershell
# Warp'ta Ctrl+P ile dosya ara
# Örnek: "ResponseParser" yaz → src/AI/ResponseParser.lua
```

#### 3. Komut Geçmişi
```powershell
# Warp'ta Ctrl+R ile geçmiş komutları ara
# Örnek: "git" yaz → tüm git komutlarını gösterir
```

#### 4. Warp AI Kullanımı
```powershell
# Warp terminalinde "#" ile başla
# Örnek: # tüm lua dosyalarını bul
# Warp komutu önerir: Get-ChildItem -Recurse -Filter *.lua
```

### VS Code ile Entegrasyon
```powershell
# Projeyi VS Code'da aç
code .

# Belirli bir dosyayı aç
code src/AI/ResponseParser.lua
```

---

## 🔄 Git Workflow

### İlk Sefer: Remote'u Kontrol Et
```powershell
# Remote repo'yu gör
git remote -v

# Beklenen:
# origin  https://github.com/swxff/neurovia-roblox.git (fetch)
# origin  https://github.com/swxff/neurovia-roblox.git (push)
```

### Günlük Geliştirme Döngüsü

#### 1. Son Değişiklikleri Çek
```powershell
# Main branch'e geç
git checkout main

# Son değişiklikleri al
git pull origin main
```

#### 2. Yeni Feature Branch Oluştur
```powershell
# Yeni branch oluştur
git checkout -b feature/yeni-ozellik

# Örnek branch isimleri:
# feature/ui-improvements
# bugfix/duplicate-code
# enhance/semantic-analysis
```

#### 3. Değişiklik Yap
```powershell
# Dosyaları düzenle
code src/AI/ResponseParser.lua

# Değişiklikleri gör
git status
git diff
```

#### 4. Commit Et
```powershell
# Tüm değişiklikleri ekle
git add .

# Veya belirli dosyaları ekle
git add src/AI/ResponseParser.lua

# Commit et (açıklayıcı mesaj)
git commit -m "fix: duplikasyon sorunu çözüldü"

# Commit mesaj formatı:
# feat: yeni özellik
# fix: bug düzeltme
# docs: dokümantasyon
# refactor: kod iyileştirme
# test: test ekleme
```

#### 5. Push Et
```powershell
# Branch'i remote'a gönder
git push origin feature/yeni-ozellik
```

#### 6. Pull Request Oluştur
1. GitHub'da repo'ya git
2. **"Compare & pull request"** butonuna tıkla
3. Değişiklikleri açıkla
4. **"Create pull request"** tıkla
5. Ekip arkadaşın review yapsın
6. Onaylandıktan sonra merge et

### Merge İşlemi (Main Branch'e)
```powershell
# Main branch'e geç
git checkout main

# Son değişiklikleri çek
git pull origin main

# Feature branch'i merge et
git merge feature/yeni-ozellik

# Push et
git push origin main

# Feature branch'i sil (opsiyonel)
git branch -d feature/yeni-ozellik
git push origin --delete feature/yeni-ozellik
```

### Conflict Çözme
```powershell
# Conflict olursa
git pull origin main

# Conflict dosyalarını düzenle
code src/AI/ResponseParser.lua

# <<<<<<< HEAD
# Senin kodon
# =======
# Arkadaşının kodu
# >>>>>>> origin/main

# Doğru versiyonu seç ve kaydet

# Conflict'i çözüldü olarak işaretle
git add .
git commit -m "fix: merge conflict çözüldü"
git push origin main
```

---

## 🛠️ Geliştirme Komutları

### Hızlı Referans
```powershell
# Build
npm run build

# Build + Install
npm run dev

# Rojo Watch Mode (Canlı Sync)
npm run watch

# Clean Build
npm run clean
npm run build
```

### Canlı Geliştirme (Rojo Sync)

#### Terminal 1: Rojo Server
```powershell
# Rojo server'ı başlat
npm run watch

# Beklenen çıktı:
# Rojo server listening on 0.0.0.0:34872
```

#### Roblox Studio'da:
1. **Plugins** → **Rojo** → **Connect**
2. **localhost:34872** bağlan
3. Artık kod değişiklikleri otomatik yansır

**Avantajları:**
- Her değişiklikte build + install yapmaya gerek yok
- Anında test edebilirsin
- Hızlı iterasyon

---

## 🐛 Sorun Giderme

### 1. Plugin Görünmüyor

**Kontrol:**
```powershell
# Plugin dosyası var mı?
Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\AI-Coder-Plugin.rbxm"

# Dosya boyutu
(Get-Item "$env:LOCALAPPDATA\Roblox\Plugins\AI-Coder-Plugin.rbxm").Length
```

**Çözüm:**
```powershell
# Tekrar kur
npm run install-plugin

# Roblox Studio'yu tamamen kapat ve aç
```

### 2. Build Hatası

**Hata: "rojo: command not found"**
```powershell
# Rojo kurulu mu?
rojo --version

# Yoksa kur (yukarıdaki Ön Gereksinimler bölümüne bak)
```

**Hata: "Error building plugin"**
```powershell
# default.project.json kontrol et
cat default.project.json

# Temiz build
npm run clean
npm run build
```

### 3. Git Hataları

**Hata: "fatal: not a git repository"**
```powershell
# Proje klasöründe misin?
cd C:\Users\[KULLANICI_ADIN]\Desktop\rblx

# .git klasörü var mı?
Test-Path .git
```

**Hata: "Permission denied (publickey)"**
```powershell
# HTTPS kullan (SSH yerine)
git remote set-url origin https://github.com/swxff/neurovia-roblox.git
```

### 4. API Hatası

**Hata: "API call failed"**
- API key'in doğru mu kontrol et
- İnternet bağlantın var mı?
- API provider'ın rate limit'i aştın mı?

**Debug Modu:**
```lua
-- src/Config.lua dosyasında:
Config.DEBUG = {
    ENABLED = true,
    LOG_LEVEL = "DEBUG",
    LOG_API_REQUESTS = true,
    LOG_API_RESPONSES = true
}
```

Build + Install yap, Roblox Studio **Output** penceresinde logları gör.

### 5. Rojo Sync Çalışmıyor

**Kontrol:**
```powershell
# Rojo server çalışıyor mu?
# Terminal 1'de: npm run watch

# Port 34872 açık mı?
netstat -an | findstr 34872
```

**Çözüm:**
- Rojo server'ı yeniden başlat
- Roblox Studio'da Rojo plugin'i yeniden connect et
- Firewall'u kontrol et

---

## 📁 Proje Yapısı Referansı

```
rblx/
├── src/                          # Kaynak kod
│   ├── Plugin.lua                # Entry point
│   ├── Config.lua                # Global ayarlar
│   ├── AI/                       # AI modülleri
│   │   ├── APIManager.lua
│   │   ├── PromptBuilder.lua
│   │   ├── ResponseParser.lua
│   │   └── [Provider]Provider.lua
│   ├── Core/                     # Temel işlevler
│   │   ├── CodeAnalyzer.lua
│   │   ├── WorkspaceManager.lua
│   │   ├── SecurityManager.lua
│   │   ├── DiffEngine.lua
│   │   └── HistoryManager.lua
│   ├── UI/                       # Kullanıcı arayüzü
│   │   ├── MainUI.lua
│   │   ├── Components.lua
│   │   └── Themes.lua
│   └── Utils/                    # Yardımcılar
│       ├── Logger.lua
│       ├── Storage.lua
│       ├── HTTPClient.lua
│       ├── Encryption.lua
│       └── Localization.lua
│
├── assets/                       # Görseller, iconlar
├── tests/                        # Test dosyaları
├── default.project.json          # Rojo yapılandırması
├── package.json                  # NPM scripts
├── plugin.rbxm                   # Build çıktısı (git'te yok)
│
├── README.md                     # Proje açıklaması
├── 00_BAŞLA_BURADAN.md           # Hızlı başlangıç (TR)
├── QUICKSTART.md                 # Hızlı başlangıç (EN)
├── SUMMARY_TR.md                 # Teknik özet (TR)
├── ARCHITECTURE_AND_IMPROVEMENTS.md  # Mimari detay
├── TECHNICAL_FIXES.md            # Bug fix detayları
└── TEAM_SETUP.md                 # ← Bu dosya!
```

---

## 📝 Yararlı Komutlar (Cheat Sheet)

### Git
```powershell
git pull origin main              # Son değişiklikleri çek
git checkout -b feature/x         # Yeni branch
git add .                         # Tüm değişiklikleri ekle
git commit -m "mesaj"             # Commit
git push origin feature/x         # Push
git status                        # Durum
git diff                          # Değişiklikleri gör
git log --oneline                 # Commit geçmişi
```

### Build & Install
```powershell
npm run build                     # Build
npm run install-plugin            # Install
npm run dev                       # Build + Install
npm run watch                     # Rojo sync
npm run clean                     # Temizle
```

### Dosya Yönetimi
```powershell
Get-ChildItem -Recurse src -Filter *.lua    # Tüm Lua dosyaları
Test-Path plugin.rbxm                       # Dosya var mı?
code src/AI/ResponseParser.lua              # VS Code'da aç
cat default.project.json                    # Dosya içeriği
```

### Roblox Plugin
```powershell
# Plugin konumu
$env:LOCALAPPDATA\Roblox\Plugins\

# Kurulu plugin'leri gör
Get-Item "$env:LOCALAPPDATA\Roblox\Plugins\*.rbxm"
```

---

## 🎯 İlk Günde Yapılacaklar Listesi

- [ ] Git, Node.js, Rojo kurulu mu kontrol et
- [ ] Projeyi klonla: `git clone ... rblx`
- [ ] Proje klasörüne gir: `cd rblx`
- [ ] Build et: `npm run build`
- [ ] Roblox Studio'ya kur: `npm run install-plugin`
- [ ] Roblox Studio'yu başlat
- [ ] Plugin'i aç (Plugins sekmesi)
- [ ] API key yapılandır (Settings)
- [ ] İlk test: "Workspace'e kırmızı bir Part oluştur"
- [ ] Warp terminal'i kur (opsiyonel)
- [ ] VS Code'da projeyi aç: `code .`
- [ ] Git branch oluştur: `git checkout -b feature/ilk-test`
- [ ] Basit bir değişiklik yap (örn: README'ye isim ekle)
- [ ] Commit + Push et
- [ ] Ekip arkadaşına Slack/Discord'dan bildir: "Kurulumu tamamladım!"

---

## 📞 İletişim & Koordinasyon

### Discord/Slack Kanalları (Öneri)
- `#genel` - Genel sohbet
- `#geliştirme` - Kod tartışmaları
- `#bugs` - Bug raporları
- `#daily-updates` - Günlük ilerleme

### GitHub Issues Kullanımı
```markdown
## Issue Şablonu

**Başlık:** [Feature] Part renk değiştirme eklenmeli

**Açıklama:**
AI komutuyla Part rengini değiştirebilmek lazım.

**Görevler:**
- [ ] WorkspaceManager'a `changePartColor()` metodu ekle
- [ ] ResponseParser'a renk tespiti ekle
- [ ] Test senaryosu yaz

**Görev Dağılımı:**
- @swxff: WorkspaceManager
- @arkadas: ResponseParser

**Deadline:** 15 Kasım 2025
```

### Code Review Süreci
1. Feature branch'te geliştirme yap
2. Pull Request oluştur
3. En az 1 kişi review yapsın
4. Onaylandıktan sonra merge et
5. Merge edildikten sonra diğer ekip üyeleri `git pull` yapsın

---

## 🎉 Tamamdır!

Artık projeyi klonladın, build ettin, Roblox Studio'ya entegre ettin ve geliştirmeye hazırsın!

**Sonraki Adımlar:**
1. `00_BAŞLA_BURADAN.md` dosyasını oku (proje genel bakış)
2. `ARCHITECTURE_AND_IMPROVEMENTS.md` dosyasını oku (mimari detay)
3. Kodda gezin, `src/` klasöründeki dosyaları incele
4. Basit bir özellik ekle ve PR oluştur

**Soru olursa:**
- Ekip arkadaşına sor
- GitHub Issues'da soru aç
- Discord/Slack'te yaz

---

**Hazırlayan:** swxff  
**Tarih:** 2025-11-08  
**Versiyon:** 1.0.0  

**Happy Coding! 🚀**
