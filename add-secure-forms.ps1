# Add Secure Forms JavaScript to All HTML Pages
Write-Host "Adding secure forms JavaScript to all HTML pages..." -ForegroundColor Green

# Secure forms script tag to add
$secureFormsScript = '    <script src="js/secure-forms.js" defer></script>'

# Get all HTML files
$htmlFiles = Get-ChildItem -Path "." -Filter "*.html" | Where-Object { $_.Name -notlike "*backup*" }

$updatedCount = 0

foreach ($file in $htmlFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        # Check if secure forms script is already present
        if ($content -notmatch "js/secure-forms\.js") {
            Write-Host "Adding secure forms script to $($file.Name)..." -ForegroundColor Yellow
            
            # Add secure forms script before closing head tag, after security.js
            if ($content -match '(\s*<script src="js/security\.js" defer></script>\s*)') {
                $content = $content -replace '(\s*<script src="js/security\.js" defer></script>\s*)', "`$1`n$secureFormsScript"
            }
            elseif ($content -match '(\s*</head>)') {
                $content = $content -replace '(\s*</head>)', "`n$secureFormsScript`n`$1"
            }
            
            Set-Content $file.FullName -Value $content -Encoding UTF8
            $updatedCount++
            Write-Host "Secure forms script added to $($file.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "$($file.Name) already has secure forms script" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error updating $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Secure forms script implementation completed!" -ForegroundColor Green
Write-Host "Updated $updatedCount files with secure form protection" -ForegroundColor Cyan