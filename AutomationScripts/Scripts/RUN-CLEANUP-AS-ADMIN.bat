@echo off
echo ============================================================
echo CLEANUP AND RECREATE ACCOUNTS - LAUNCHER
echo ============================================================
echo.
echo This will:
echo 1. Remove existing Admin and iBridge User accounts
echo 2. Remove their profile folders
echo 3. Create fresh accounts with correct passwords
echo.
echo Admin Account: Username = Admin, Password = IBr1dG3Pc
echo User Account:  Username = iBridge User, Password = Abc654321!
echo.
pause

echo.
echo Running cleanup script with Administrator privileges...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0CLEANUP-AND-RECREATE-ACCOUNTS.ps1"

echo.
echo Cleanup completed. Press any key to exit...
pause > nul
