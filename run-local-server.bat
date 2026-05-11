@echo off
REM iBridge Local Development Server
REM This script starts the Python HTTP server on port 8080 to serve the Website folder

echo.
echo ========================================
echo  iBridge Local Development Server
echo ========================================
echo.

cd /d "c:\Users\Lwandile Gasela\iBridge\Website"

echo Starting Python HTTP Server on port 8080...
echo Serving files from: %cd%
echo.
echo Access the site at: http://localhost:8080
echo Careers page: http://localhost:8080/careers.html
echo.
echo Press Ctrl+C to stop the server.
echo.

python -m http.server 8080

pause
