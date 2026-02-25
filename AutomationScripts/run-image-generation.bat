@echo off
setlocal

if "%OPENAI_API_KEY%"=="" (
  echo OPENAI_API_KEY is not set.
  echo.
  echo In PowerShell, run:
  echo   $env:OPENAI_API_KEY="your_key_here"
  echo Then run this .bat again from the same terminal session.
  exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0generate-african-site-images.ps1" -UpdateReferences
if errorlevel 1 (
  echo Image generation failed.
  exit /b 1
)

echo Image generation completed.
exit /b 0
