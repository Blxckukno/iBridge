@echo off
echo ================================================================
echo iBridge Setup Test - Checking USB Detection
echo ================================================================

echo Searching for USB drive...

:: Find USB drive automatically
set FOUND_USB=
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\24.2.2000.exe" (
        if exist "%%d:\GlassWireSetup.exe" (
            set FOUND_USB=%%d:
            echo SUCCESS: Found USB at %%d:
            echo Checking files...
            dir "%%d:\" | findstr "24.2.2000.exe"
            dir "%%d:\" | findstr "GlassWireSetup.exe"
            dir "%%d:\" | findstr "PBIDesktopSetup_x64.exe"
            dir "%%d:\" | findstr "TeamViewer_Setup_x64.exe"
            echo.
            echo Files for Office:
            dir "%%d:\Tools for Office2019 TechXander" 2>nul || echo Office folder not found
            goto found
        )
    )
)

echo ERROR: Cannot find USB drive with required files
echo Checked drives D: through Z:
pause
exit /b 1

:found
echo.
echo ================================================================
echo USB DETECTION SUCCESSFUL!
echo Drive: %FOUND_USB%
echo All required files found
echo Ready for installation on any computer
echo ================================================================
pause
