@echo off
echo ========================================
echo Rojo Plugin Otomatik Kurulum
echo ========================================
echo.

set "PLUGIN_URL=https://github.com/rojo-rbx/rojo/releases/latest/download/rojo-plugin.rbxm"
set "PLUGIN_PATH=%LOCALAPPDATA%\Roblox\Plugins\rojo-plugin.rbxm"

echo [1/3] Rojo plugin'i indiriliyor...
echo.

REM PowerShell ile indir
powershell -Command "try { Invoke-WebRequest -Uri '%PLUGIN_URL%' -OutFile 'rojo-plugin.rbxm' -UseBasicParsing; Write-Host '[OK] ?ndirildi' -ForegroundColor Green } catch { Write-Host '[ERROR] ?ndirme ba?ar?s?z!' -ForegroundColor Red; Write-Host 'Manuel indirme linki: %PLUGIN_URL%' -ForegroundColor Yellow; exit 1 }"

if errorlevel 1 (
    echo.
    echo ========================================
    echo Manuel Kurulum Gerekli
    echo ========================================
    echo.
    echo 1. ?u linke git:
    echo    %PLUGIN_URL%
    echo.
    echo 2. Dosyay? indir (rojo-plugin.rbxm)
    echo.
    echo 3. ?u komutla kur:
    echo    copy rojo-plugin.rbxm "%PLUGIN_PATH%"
    echo.
    pause
    exit /b 1
)

echo [2/3] Plugins klas?r? olu?turuluyor...
if not exist "%LOCALAPPDATA%\Roblox\Plugins" (
    mkdir "%LOCALAPPDATA%\Roblox\Plugins"
    echo [OK] Klas?r olu?turuldu
)

echo [3/3] Plugin kuruluyor...
copy /Y rojo-plugin.rbxm "%PLUGIN_PATH%"

if errorlevel 1 (
    echo [ERROR] Kurulum ba?ar?s?z!
    pause
    exit /b 1
)

echo.
echo ========================================
echo ? BA?ARILI! Rojo Plugin Kuruldu
echo ========================================
echo.
echo Konum: %PLUGIN_PATH%
echo.
echo Sonraki Ad?mlar:
echo 1. Roblox Studio'yu a? (veya yeniden ba?lat)
echo 2. Plugins ? Rojo butonunu g?receksin
echo 3. 'npm run watch' komutunu ?al??t?r
echo 4. Studio'da Rojo ? Connect t?kla
echo.
echo Detayl? kurulum: WATCH_MODE_SETUP.md
echo.
pause
