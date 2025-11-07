# Plugin Sorun Giderme Rehberi

## Plugin Studio'da Görünmüyor

### 1. Studio'yu Tamamen Kapatın
- Tüm Studio pencerelerini kapatın
- Task Manager'dan `RobloxStudioBeta.exe` veya `RobloxStudio.exe` process'lerini kontrol edin
- Varsa sonlandırın
- Studio'yu yeniden açın

### 2. Plugin Dosyasını Kontrol Edin
- Dosya konumu: `%LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm`
- Dosya boyutu: ~46 KB (0 değil!)
- Son güncelleme: Yeni build'den sonra güncellenmiş olmalı

### 3. Studio Output Penceresini Kontrol Edin
- Studio'da: View → Output
- Plugin yüklenirken hata mesajı var mı kontrol edin
- Hata varsa, hata mesajını not edin

### 4. Plugin Yapısını Kontrol Edin
Plugin doğru yapıda olmalı:
```
Plugin (Instance)
  └── Main (Script) ← Bu Script olmalı, ModuleScript değil!
      └── Source: Plugin.server.lua içeriği
  └── Config (ModuleScript)
  └── Utils (Folder)
  └── Core (Folder)
  └── AI (Folder)
  └── UI (Folder)
```

### 5. Test Plugin Oluşturun
Basit bir test plugin'i oluşturup çalışıp çalışmadığını kontrol edin.

### 6. Plugin Klasörünü Temizleyin
Bazen eski plugin dosyaları sorun yaratabilir:
1. Studio'yu kapatın
2. `%LOCALAPPDATA%\Roblox\Plugins\` klasöründeki tüm `.rbxm` dosyalarını geçici olarak başka bir yere taşıyın
3. Sadece `AI-Coder-Plugin.rbxm` dosyasını geri koyun
4. Studio'yu açın

### 7. Rojo Build'i Kontrol Edin
```powershell
npm run build
```
Build başarılı olmalı ve hata mesajı olmamalı.

### 8. Plugin İçeriğini Kontrol Edin
Plugin.server.lua dosyasında syntax hatası olmamalı. İlk satırlar:
```lua
local Config = require(script.Config)
```
Bu satır çalışmalı - eğer Config modülü bulunamazsa plugin yüklenemez.

## Hala Çalışmıyorsa

1. Studio Output penceresindeki hata mesajlarını paylaşın
2. Plugin dosyasının boyutunu kontrol edin (0 bytes olmamalı)
3. Build log'larını kontrol edin


