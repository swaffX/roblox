@echo off
echo ========================================
echo Starting Rojo Watch Mode...
echo ========================================
echo.
echo This will keep running until you press Ctrl+C
echo Connect to this server from Roblox Studio using the Rojo plugin
echo.

set "ROJO_PATH=%USERPROFILE%\.cargo\bin\rojo.exe"

if not exist "%ROJO_PATH%" (
    echo [ERROR] Rojo not found!
    echo Please install with: cargo install rojo
    pause
    exit /b 1
)

echo [INFO] Starting Rojo server...
echo [INFO] Server will be available at: http://localhost:34872
echo [INFO] Press Ctrl+C to stop
echo.

"%ROJO_PATH%" serve default.project.json

REM If we get here, server stopped (user pressed Ctrl+C)
echo.
echo [INFO] Rojo server stopped.
pause

