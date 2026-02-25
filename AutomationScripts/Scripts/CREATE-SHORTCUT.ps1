$WshShell = New-Object -comObject WScript.Shell
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\iBridge Setup FIXED.lnk"
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "C:\iBridge_Setup\RUN-ENHANCED-SETUP-FIXED.bat"
$Shortcut.WorkingDirectory = "C:\iBridge_Setup"
$Shortcut.Description = "iBridge Enhanced Setup - Fixed Drive Detection"
$Shortcut.Save()
Write-Host "Desktop shortcut created: $shortcutPath" -ForegroundColor Green
