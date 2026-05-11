@echo off
setlocal

set ROOT=%~dp0
set FRONTEND_PORT=8080
set BACKEND_PORT=5000

echo ==========================================
echo   iBridge Safe Local Launcher
echo ==========================================
echo.
echo This launcher avoids PowerShell and serves the Website folder directly.
echo.

where python >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Python is not available in PATH.
  pause
  exit /b 1
)

where py >nul 2>nul
if %errorlevel%==0 (
  set PY_CMD=py
) else (
  set PY_CMD=python
)

echo [1/3] Starting backend API on port %BACKEND_PORT%...
start "iBridge Backend API" cmd /k "cd /d "%ROOT%BackendServices\backend" && %PY_CMD% app.py"

echo [2/3] Starting static frontend on port %FRONTEND_PORT%...
start "iBridge Frontend Static" cmd /k "cd /d "%ROOT%" && %PY_CMD% -m http.server %FRONTEND_PORT% --directory Website"

echo [3/3] Waiting for services to start...
timeout /t 6 /nobreak >nul

echo.
echo Main site:
echo   http://localhost:%FRONTEND_PORT%/index.html
echo.
echo Main pages:
echo   http://localhost:%FRONTEND_PORT%/about.html
echo   http://localhost:%FRONTEND_PORT%/services.html
echo   http://localhost:%FRONTEND_PORT%/team.html
echo   http://localhost:%FRONTEND_PORT%/contact.html
echo   http://localhost:%FRONTEND_PORT%/careers.html
echo   http://localhost:%FRONTEND_PORT%/privacy.html
echo   http://localhost:%FRONTEND_PORT%/compliance.html
echo.
echo Backend health:
echo   http://127.0.0.1:%BACKEND_PORT%/api/health
echo.

start "" "http://localhost:%FRONTEND_PORT%/index.html"

echo Keep both command windows open while testing the site.
echo If the page still cannot be reached, check the two command windows for errors.
echo.
pause
exit /b 0
