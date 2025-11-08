@echo off
echo ========================================
echo Building AI Coder Plugin...
echo ========================================
REM Try to find Rojo in PATH first
where rojo >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "ROJO_CMD=rojo"
) else (
    set "ROJO_CMD=%USERPROFILE%\.cargo\bin\rojo.exe"
    if not exist "!ROJO_CMD!" (
        echo [ERROR] Rojo not found!
        echo Please install with: cargo install rojo
        pause
        exit /b 1
    )
)

echo [1/3] Building plugin with Rojo...
%ROJO_CMD% build default.project.json -o plugin.rbxm

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)

if not exist "plugin.rbxm" (
    echo [ERROR] Build file not created!
    pause
    exit /b 1
)

echo [2/3] Build successful! (plugin.rbxm created)
echo [3/3] Installing plugin to Roblox Studio...

REM Create Plugins directory if it doesn't exist
if not exist "%LOCALAPPDATA%\Roblox\Plugins" (
    mkdir "%LOCALAPPDATA%\Roblox\Plugins"
    echo Created Plugins directory
)

REM Copy plugin to Roblox Plugins folder
echo Copying plugin to Roblox Plugins directory...
copy /Y plugin.rbxm "%LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm"

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy plugin!
    pause
    exit /b 1
)

REM Verify installation
if not exist "%LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm" (
    echo [ERROR] Plugin file not found after copy!
    pause
    exit /b 1
)

echo.
echo ========================================
echo SUCCESS! Plugin installed to:
echo %LOCALAPPDATA%\Roblox\Plugins\AI-Coder-Plugin.rbxm
echo ========================================
echo.
echo Next steps:
echo 1. Close Roblox Studio completely (if open)
echo 2. Reopen Roblox Studio
echo 3. Go to Plugins tab
echo 4. Click "AI Coder" button
echo.
pause


