@echo off
:: Quick Test - Enhanced Setup Launch

echo Testing Enhanced Setup Launch...
echo Current directory: %CD%
echo Script directory: %~dp0

echo.
echo Files in directory:
dir "%~dp0*.bat"

echo.
echo Testing if RUN-ENHANCED-SETUP.bat exists:
if exist "%~dp0RUN-ENHANCED-SETUP.bat" (
    echo SUCCESS: RUN-ENHANCED-SETUP.bat found at %~dp0
    echo File size: 
    for %%i in ("%~dp0RUN-ENHANCED-SETUP.bat") do echo %%~zi bytes
) else (
    echo ERROR: RUN-ENHANCED-SETUP.bat not found at %~dp0
)

echo.
echo Press any key to continue...
pause >nul
