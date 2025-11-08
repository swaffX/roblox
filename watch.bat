@echo off
echo ========================================
echo Rojo Watch Mode Ba?lat?l?yor...
echo ========================================
echo.
echo Bu pencereyi A?IK TUTUN!
echo De?i?iklikler otomatik olarak Studio'ya yans?yacak.
echo.
echo Durdurmak i?in: Ctrl+C
echo.
echo ========================================
echo.

set "ROJO_PATH=%USERPROFILE%\.cargo\bin\rojo.exe"

if not exist "%ROJO_PATH%" (
    echo [ERROR] Rojo bulunamad?!
    echo L?tfen ?unu ?al??t?r?n: cargo install rojo
    echo.
    echo Veya Rojo'yu indirin: https://github.com/rojo-rbx/rojo/releases
    pause
    exit /b 1
)

echo [INFO] Rojo server ba?lat?l?yor...
echo [INFO] Server adresi: http://localhost:34872
echo [INFO] Studio'da: Plugins ? Rojo ? Connect
echo.

"%ROJO_PATH%" serve default.project.json

REM Server durduruldu
echo.
echo [INFO] Rojo server durduruldu.
pause
