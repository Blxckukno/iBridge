@echo off
echo ==========================================
echo iBridge Profile Cleanup Tool
echo ==========================================
echo.
echo This will remove unwanted shortcuts from:
echo - Admin profile
echo - iBridge User profile
echo.
echo ONLY these applications will remain:
echo - TeamViewer
echo - IT STUFF folder
echo - Tools for Office2019 TechXander
echo - 24.2.2000.exe
echo - AnyDesk
echo - GlassWire
echo - Power BI Desktop
echo.
echo All other applications will be removed from
echo Admin and iBridge User profiles but will
echo remain untouched on Lwandile Gasela profile.
echo.
pause

PowerShell -ExecutionPolicy Bypass -File "%~dp0Profile-Isolation.ps1"

echo.
echo Cleanup completed! Press any key to close...
pause >nul
