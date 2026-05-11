@echo off
cd /d "c:\Users\Lwandile Gasela\iBridge"
node BackendServices\local-server.js
if errorlevel 1 (
  echo Node.js not found, using Python HTTP server...
  cd /d "c:\Users\Lwandile Gasela\iBridge\Website"
  python -m http.server 8080
)
pause