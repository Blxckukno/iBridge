# This PowerShell script will attempt to fix Python installation issues on Windows
# It will:
# 1. Check for Python in PATH
# 2. Attempt to repair Python via the Microsoft Store if not found
# 3. Add Python to PATH if installed but not in PATH

$pythonPath = Get-Command python -ErrorAction SilentlyContinue
$pyPath = Get-Command py -ErrorAction SilentlyContinue

if ($pythonPath -or $pyPath) {
    Write-Host "Python is already installed and available in PATH."
    python --version
    exit 0
}

# Try to find Python in the default WindowsApps location
$windowsAppsPython = "$env:LOCALAPPDATA\Microsoft\WindowsApps\python.exe"
if (Test-Path $windowsAppsPython) {
    Write-Host "Python executable found in WindowsApps. Adding to PATH..."
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*WindowsApps*") {
        [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$env:LOCALAPPDATA\Microsoft\WindowsApps", "User")
        Write-Host "Added WindowsApps to PATH. Please restart your terminal."
    } else {
        Write-Host "WindowsApps already in PATH."
    }
    exit 0
}

# Try to launch the Python Install Manager if available
$pythonManager = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WindowsApps" -Filter "Python*Manager*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pythonManager) {
    Write-Host "Launching Python Install Manager to repair or install Python..."
    Start-Process $pythonManager.FullName
    exit 0
}

Write-Host "Python is not installed. Please download and install Python from https://www.python.org/downloads/ and ensure you check 'Add Python to PATH' during installation."
exit 1
