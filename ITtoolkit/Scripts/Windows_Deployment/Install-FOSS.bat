@echo off
echo Installing FOSS Applications...
echo.

cd /d "%USERPROFILE%\Desktop\FOSS_Tools"

echo Installing 7-Zip...
7z2408-x64.exe /S
if %errorlevel% equ 0 (
    echo SUCCESS: 7-Zip installed
) else (
    echo FAILED: 7-Zip installation failed
)
echo.

echo Installing Firefox...
Firefox-Setup.exe /S
if %errorlevel% equ 0 (
    echo SUCCESS: Firefox installed
) else (
    echo FAILED: Firefox installation failed
)
echo.

echo Installing KeePassXC...
msiexec /i "KeePassXC-2.7.9-Win64.msi" /qn
if %errorlevel% equ 0 (
    echo SUCCESS: KeePassXC installed
) else (
    echo FAILED: KeePassXC installation failed
)
echo.

echo Installing VirtualBox...
VirtualBox-7.1.4-165100-Win.exe --silent
if %errorlevel% equ 0 (
    echo SUCCESS: VirtualBox installed
) else (
    echo FAILED: VirtualBox installation failed
)
echo.

echo.
echo ===================================
echo    FOSS INSTALLATION COMPLETED
echo ===================================
echo.
echo Installed applications:
echo - 7-Zip (File compression)
echo - Firefox (Web browser)
echo - KeePassXC (Password manager)
echo - VirtualBox (Virtualization)
echo.
echo All software is 100%% free and open-source!
echo.
pause
