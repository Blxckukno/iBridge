# This script will close all VS Code processes and open the Copilot sign-in page in your default browser.
# Note: You will need to manually sign in after the browser opens.

# Close all VS Code processes
taskkill /IM Code.exe /F

# Wait a moment to ensure VS Code is closed
Start-Sleep -Seconds 2

# Open the Copilot sign-in page
Start-Process "https://github.com/login/device"

Write-Host "VS Code closed and Copilot sign-in page opened. Please complete the sign-in in your browser, then reopen VS Code."