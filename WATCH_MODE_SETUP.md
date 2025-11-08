# Rojo Watch Mode Setup Guide

## 🚀 Otomatik Yansıma Kurulumu

### Adım 1: Rojo Plugin'i İndir ve Kur

**İndirme Linki:**
https://github.com/rojo-rbx/rojo/releases/latest/download/rojo-plugin.rbxm

**Kurulum:**
```powershell
# İndirdikten sonra bu komutu çalıştır:
Copy-Item rojo-plugin.rbxm "$env:LOCALAPPDATA\Roblox\Plugins\rojo-plugin.rbxm" -Force
```

**Alternatif: Roblox'tan Yükle**
https://create.roblox.com/store/asset/13916111004/Rojo

---

### Adım 2: Watch Mode Başlat

```powershell
npm run watch
```

**Beklenen Çıktı:**
```
Starting Rojo server...
Server listening at http://localhost:34872
```

---

### Adım 3: Studio'da Bağlan

1. Roblox Studio'yu aç
2. **Plugins** sekmesine git
3. **Rojo** butonunu bul
4. **Connect** tıkla
5. Adres: **localhost:34872**

**Bağlandığında:**
```
✅ Connected to Rojo
```

---

### Adım 4: Test Et

```powershell
# Yeni terminal aç:
notepad src/Config.lua

# Bir yorum ekle:
# -- TEST: Otomatik yansıma çalışıyor!

# Kaydet (Ctrl+S)
# → Studio'da ANINDA güncellenir! 🚀
```

---

## 🎯 Günlük Kullanım

### Her Gün:
```powershell
# 1. Watch mode başlat
npm run watch

# 2. Studio'yu aç
# 3. Rojo → Connect
# 4. Kod yaz, kaydet → Otomatik yansır!
```

### Kapatma:
```powershell
# Terminal'de Ctrl+C
# Watch mode durur
```

---

## 👥 Ekip Arkadaşın İçin

Arkadaşına bu adımları gönder:

```powershell
# 1. Repo klonla
git clone https://github.com/swaffX/neurovia-roblox.git rblx
cd rblx
npm install

# 2. Rojo plugin'i indir ve kur (yukarıdaki link)

# 3. Watch mode başlat
npm run watch

# 4. Studio'da bağlan
Plugins → Rojo → Connect → localhost:34872
```

---

## 🐛 Sorun Giderme

### Rojo Plugin Görünmüyor
1. Studio'yu kapat
2. Plugin dosyasını kontrol et:
   ```powershell
   Test-Path "$env:LOCALAPPDATA\Roblox\Plugins\rojo-plugin.rbxm"
   ```
3. Studio'yu aç

### Bağlanamıyor
1. Watch mode çalışıyor mu kontrol et
2. Başka bir şey port 34872'yi kullanıyor olabilir:
   ```powershell
   netstat -ano | findstr :34872
   ```

### Değişiklikler Yansımıyor
1. Bağlantıyı kontrol et (Studio'da Rojo butonu yeşil olmalı)
2. Watch mode'u yeniden başlat:
   ```powershell
   # Terminal'de Ctrl+C
   npm run watch
   ```
3. Studio'da tekrar bağlan

---

## 📊 Performans

**Manuel Mod:** 70 saniye/değişiklik  
**Otomatik Mod:** 2 saniye/değişiklik  
**35x daha hızlı!** 🚀

---

**Hazır! Watch mode artık aktif.**
