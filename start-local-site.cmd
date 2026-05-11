@echo off
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "FRONTEND_URL=http://localhost:8080/index.html"
set "BACKEND_URL=http://127.0.0.1:5000/api/health"

echo ==========================================
echo   iBridge Local Site Launcher
echo ==========================================
echo.
echo Workspace: %ROOT%
echo.

where node >nul 2>nul
if errorlevel 1 (
  set "NODE_AVAILABLE=0"
) else (
  set "NODE_AVAILABLE=1"
)

where python >nul 2>nul
if errorlevel 1 (
  set "PYTHON_AVAILABLE=0"
) else (
  set "PYTHON_AVAILABLE=1"
)

if "%PYTHON_AVAILABLE%"=="0" (
  echo [WARNING] Python is not available in PATH.
) else (
  echo [1/3] Starting backend API on port 5000...
  start "iBridge Backend API" cmd /k "cd /d "%ROOT%BackendServices\backend" && python app.py"
)

if "%NODE_AVAILABLE%"=="1" (
  echo [2/3] Starting frontend site on port 8080 with Node.js...
  start "iBridge Frontend Site" cmd /k "cd /d "%ROOT%" && node BackendServices\local-server.js"
) else if "%PYTHON_AVAILABLE%"=="1" (
  echo [2/3] Node.js not found. Starting frontend site with Python HTTP server on port 8080...
  start "iBridge Frontend Site" cmd /k "cd /d "%ROOT%Website" && python -m http.server 8080"
) else (
  echo [2/3] Frontend server cannot start because neither Node.js nor Python is available.
)

echo [3/3] Waiting for services to warm up...
timeout /t 6 /nobreak >nul

echo.
echo Main site:
echo   %FRONTEND_URL%
echo.
echo Key pages:
echo   http://localhost:8080/about.html
echo   http://localhost:8080/services.html
echo   http://localhost:8080/team.html
echo   http://localhost:8080/contact.html
echo   http://localhost:8080/careers.html
echo   http://localhost:8080/privacy.html

echo.
if "%NODE_AVAILABLE%"=="1" (
  start "iBridge Site" "microsoft-edge:%FRONTEND_URL%"
) else if "%PYTHON_AVAILABLE%"=="1" (
  start "iBridge Site" "microsoft-edge:%FRONTEND_URL%"
) else (
  echo [ERROR] No browser launch because frontend server is not available.
)

pause
exit /b 0
