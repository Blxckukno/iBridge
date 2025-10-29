@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title IT Toolkit - Security Menu

:: Root directory for menu discovery is the folder of this file
set MENU_ROOT=%~dp0

:: Elevation: ensure the menu runs as Administrator so called scripts run inline
fltmc >nul 2>&1
if errorlevel 1 (
  echo > Requesting Administrator privileges for IT Toolkit Menu...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)

:: Optional debug toggle (affects orchestrator only)
set DEBUG=0

:main
cls
echo =============================================================
echo         IT Toolkit - Security and Maintenance Menu
echo =============================================================
echo Root: %MENU_ROOT%
if "%DEBUG%"=="1" (echo Mode: DEBUG  ^(passed to Run-All-Security-Tasks.bat^))
echo.
echo Scanning for available tasks (.bat and .ps1)...

:: Load verified scripts list if available
set VERIFIED_LIST=
if exist "Verified_Safe_Scripts.txt" (
  for /f "usebackq delims=" %%L in ("Verified_Safe_Scripts.txt") do (
    set "VERIFIED_LIST=!VERIFIED_LIST!%%L;"
  )
)

set IDX=0
for /f "delims=" %%F in ('dir /s /b "%MENU_ROOT%*.bat" 2^>nul') do (
  set "FULL=%%~fF"
  if /I not "!FULL!"=="%~f0" (
    set /a IDX+=1
    set "ITEM!IDX!=!FULL!"
    set "REL!IDX!=!FULL:%MENU_ROOT%=!"
    set "EXT!IDX!=bat"
  )
)
for /f "delims=" %%F in ('dir /s /b "%MENU_ROOT%*.ps1" 2^>nul') do (
  set "FULL=%%~fF"
  set "BASE=%%~dpnF"
  if not exist "!BASE!.bat" (
    set /a IDX+=1
    set "ITEM!IDX!=!FULL!"
    set "REL!IDX!=!FULL:%MENU_ROOT%=!"
    set "EXT!IDX!=ps1"
  )
)

if %IDX%==0 (
  echo No .bat tasks found under: %MENU_ROOT%
  echo Press any key to exit...
  pause >nul
  goto :eof
)

echo.
for /L %%I in (1,1,%IDX%) do (
  set "REL=!REL%%I!"
  set "EXT=!EXT%%I!"
  set "FILENAME="
  for %%N in ("!REL!") do set "FILENAME=%%~nxN"
  
  set "STATUS= "
  echo "!VERIFIED_LIST!" | find "!FILENAME!" >nul && set "STATUS=*"
  
  if /I "!EXT!"=="bat" (
    echo   [%%I] [BAT!STATUS!] !REL!
  ) else (
    echo   [%%I] [PS1!STATUS!] !REL!
  )
)
echo.
echo   [R] Refresh list
echo   [S] Security verification
echo   [V] Verify all scripts (syntax only)
echo   [D] Toggle DEBUG for orchestrator
echo   [X] Exit
echo.
echo   * = Verified safe and working script
echo.
set /p CH=Select an option ^(number/R/S/V/D/X^): 

if /I "%CH%"=="X" goto :eof
if /I "%CH%"=="R" goto :main
if /I "%CH%"=="S" (
  echo Running comprehensive security verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Security-Verification-Simple.ps1"
  echo.
  echo Press any key to refresh menu...
  pause >nul
  goto :main
)
if /I "%CH%"=="V" (
  echo Running script syntax verification...
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%MENU_ROOT%Verify-Scripts-Simple.ps1"
  echo.
  echo Press any key to refresh menu...
  pause >nul
  goto :main
)
if /I "%CH%"=="D" (
  if "%DEBUG%"=="1" (set DEBUG=0) else (set DEBUG=1)
  goto :main
)

set "TARGET="
for /f "tokens=1 delims=0123456789" %%A in ("%CH%") do set NONNUM=%%A
if defined NONNUM (
  echo Invalid selection.
  timeout /t 1 >nul
  goto :main
)

for /f "delims=" %%P in ("!ITEM%CH%!" ) do set TARGET=%%~fP
if not defined TARGET (
  echo Invalid number.
  timeout /t 1 >nul
  goto :main
)

cls
echo =============================================================
echo Running: %TARGET%
echo =============================================================

:: Determine extension and run accordingly
for %%X in ("%TARGET%") do set SEL_EXT=%%~xX

set ARGS=
if /I "%SEL_EXT%"==".bat" (
  echo %TARGET% | find /I "Run-All-Security-Tasks.bat" >nul && (
    if "%DEBUG%"=="1" set ARGS=/debug
  )
  call "%TARGET%" %ARGS%
) else if /I "%SEL_EXT%"==".ps1" (
  pushd "%~dp0"
  for %%D in ("%TARGET%") do pushd "%%~dpD"
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TARGET%"
  popd
  popd
) else (
  echo Unsupported file type: %SEL_EXT%
)

echo.
echo Task finished. Press any key to return to menu...
pause >nul
goto :main
