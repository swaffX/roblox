@echo off
echo ========================================
echo Installing Neurovia Coder Plugin
echo ========================================
echo.

REM Create plugins directory if doesn't exist
if not exist "%LOCALAPPDATA%\Roblox\Plugins" (
    mkdir "%LOCALAPPDATA%\Roblox\Plugins"
    echo Created Plugins directory
)

REM Copy plugin file
echo Copying neurovia-coder-full.lua to Plugins folder...
copy /Y "%~dp0neurovia-coder-full.lua" "%LOCALAPPDATA%\Roblox\Plugins\neurovia-coder.lua"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy plugin!
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Plugin installed to:
echo %LOCALAPPDATA%\Roblox\Plugins\neurovia-coder.lua
echo ========================================
echo.
echo Next steps:
echo 1. Close Roblox Studio completely (if open)
echo 2. Reopen Roblox Studio
echo 3. Go to Plugins tab
echo 4. Click "Neurovia Coder" button
echo 5. Use /setkey command to configure API key
echo.
pause
