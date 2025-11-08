# Plan Mode Cleanup Script
$pluginPath = "C:\Users\swxff\AppData\Local\Roblox\Plugins\NeuroviaVibe.lua"
$backupPath = "C:\Users\swxff\Desktop\rblx\NeuroviaVibe_backup.lua"

Write-Host "Reading files..." -ForegroundColor Cyan

# Read both files
$content = Get-Content $pluginPath -Raw
$backup = Get-Content $backupPath -Raw

Write-Host "Removing Plan Mode code block (lines 2573-2894)..." -ForegroundColor Yellow

# Split into lines for precise editing
$lines = $content -split "`n"

# Remove lines 2572-2893 (0-indexed: 2571-2892)
$before = $lines[0..2571] -join "`n"
$after = $lines[2893..($lines.Count-1)] -join "`n"

# Rebuild without Plan Mode
$cleaned = $before + "`n" + $after

# Remove all [PLAN MODE] debug prints
$cleaned = $cleaned -replace "print\('\[PLAN MODE\][^']*'[^)]*\)", ''

Write-Host "Writing cleaned file..." -ForegroundColor Green
$cleaned | Set-Content $pluginPath -Encoding UTF8 -NoNewline

Write-Host "Done! Plan Mode code removed." -ForegroundColor Green
Write-Host "Please open Studio and test."
