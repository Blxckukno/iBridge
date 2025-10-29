@echo off
echo Enabling Windows Defender Real-Time Protection...
echo This requires Administrator privileges.
echo.

:: Check for admin privileges
fltmc >nul 2>&1
if errorlevel 1 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','%~f0' -Verb RunAs"
    exit /b
)

echo Running as Administrator - enabling Windows Defender...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Set-MpPreference -DisableRealtimeMonitoring $false; Write-Host 'SUCCESS: Windows Defender Real-Time Protection Enabled' -ForegroundColor Green } catch { Write-Host 'ERROR: Failed to enable Windows Defender:' $_.Exception.Message -ForegroundColor Red }"

echo.
echo Verifying Windows Defender status...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $status = Get-MpComputerStatus; Write-Host 'Real-Time Protection:' $status.RealTimeProtectionEnabled -ForegroundColor $(if ($status.RealTimeProtectionEnabled) {'Green'} else {'Red'}) } catch { Write-Host 'Could not verify Defender status' -ForegroundColor Yellow }"

echo.
echo Press any key to continue...
pause >nul
