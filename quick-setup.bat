@echo off
REM Quick setup script for new contributors
echo ========================================
echo Neurovia AI Coder - Quick Setup
echo ========================================
echo.
echo Bu script yeni kat?l?mc?lar i?in otomatik kurulum yapar.
echo.
pause

echo [1/4] NPM ba??ml?l?klar?n? y?kl?yorum...
call npm install
if errorlevel 1 (
    echo [ERROR] npm install ba?ar?s?z!
    pause
    exit /b 1
)

echo.
echo [2/4] Rojo plugin'i kuruyorum...
call setup-watch.bat
if errorlevel 1 (
    echo [WARNING] Rojo plugin kurulumu ba?ar?s?z olabilir, manuel kurulum gerekebilir
)

echo.
echo [3/4] Plugin'i build ediyorum...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build ba?ar?s?z!
    pause
    exit /b 1
)

echo.
echo [4/4] Plugin'i Roblox Studio'ya kuruyorum...
call npm run install-plugin
if errorlevel 1 (
    echo [ERROR] Plugin kurulumu ba?ar?s?z!
    pause
    exit /b 1
)

echo.
echo ========================================
echo ? KURULUM TAMAMLANDI!
echo ========================================
echo.
echo Sonraki ad?mlar:
echo.
echo 1. Geli?tirme i?in watch mode ba?lat:
echo    npm run watch
echo.
echo 2. Roblox Studio'yu a?
echo.
echo 3. Studio'da: Plugins ? Rojo ? Connect (localhost:34872)
echo.
echo 4. Art?k src/ dosyalar?n? d?zenle, otomatik yans?r!
echo.
echo Detaylar: WARP.md veya WATCH_MODE_SETUP.md
echo.
pause
