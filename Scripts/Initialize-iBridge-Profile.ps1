# Run this to complete iBridge User profile initialization
$password = ConvertTo-SecureString "Abc654321!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("iBridge User", $password)

Write-Host "Initializing iBridge User profile..." -ForegroundColor Yellow
Start-Process cmd.exe -Credential $credential -ArgumentList '/c', 'echo Profile initialized successfully & pause' -WindowStyle Normal -Wait
Write-Host "Profile initialization completed!" -ForegroundColor Green
