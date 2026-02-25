# iBridge User Shortcut Setup - Run AFTER first login
Write-Host ""
Write-Host "iBridge User Shortcut Setup" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

$shortcutsSource = "C:\iBridge_Shortcuts_Ready"
$iBridgeDesktop = "C:\Users\iBridge User\Desktop"

if (Test-Path $shortcutsSource) {
    if (Test-Path $iBridgeDesktop) {
        try {
            $shortcuts = Get-ChildItem $shortcutsSource -Filter "*.lnk" -ErrorAction SilentlyContinue
            $copiedCount = 0
            foreach ($shortcut in $shortcuts) {
                $destPath = "$iBridgeDesktop\$($shortcut.Name)"
                Copy-Item $shortcut.FullName $destPath -Force
                Write-Host "Copied: $($shortcut.Name)" -ForegroundColor Green
                $copiedCount++
            }
            Write-Host ""
            Write-Host "SUCCESS: Copied $copiedCount shortcuts to iBridge User desktop" -ForegroundColor Green
            
            # Clean up
            Remove-Item $shortcutsSource -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleanup completed" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Failed to copy shortcuts: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: iBridge User desktop not found!" -ForegroundColor Red
        Write-Host "Please log in to iBridge User first to create the desktop" -ForegroundColor Yellow
    }
} else {
    Write-Host "INFO: No shortcuts prepared during installation" -ForegroundColor Gray
}

Write-Host ""
Write-Host "iBridge User setup completed!" -ForegroundColor Green
Write-Host ""
pause
