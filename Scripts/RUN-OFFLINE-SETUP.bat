@echo off
title iBridge Offline Setup Launcher
color 0A

echo.
echo  ========================================
echo   iBridge Offline Setup v3.0
echo  ========================================
echo.
echo  This will create:
echo  - Admin account (Password: IBr1dG3Pc)
echo  - iBridge User account (Password: Abc654321!)
echo.
echo  Install applications from USB:
echo  - TeamViewer Setup x64
echo  - 24.2.2000 
echo  - AnyDesk
echo  - GlassWire Setup  
echo  - Power BI Desktop Setup x64
echo  - Tools for Office 2019 TechXander
echo  - Office shortcuts only (Desktop-Mtn folder)
echo.
echo  Excluded files (not installed):
echo  - epi_win_live_installer_2.exe
echo  - ESET KEY.txt
echo  - Genesys Cloud login
echo  - prey-installer
echo.
echo  iBridge User will get special shortcuts:
echo  - Word, Excel, Outlook, PowerPoint
echo  - Microsoft 365 Online
echo  - MS Teams (installed)
echo  - New Citrix Gateway
echo.
echo  ========================================
echo.
pause

echo Starting offline setup...
PowerShell -ExecutionPolicy Bypass -File "%~dp0iBridge-Offline-Setup.ps1"

echo.
echo Setup completed! Check the results above.
pause
