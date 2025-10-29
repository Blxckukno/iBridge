# Reduces default background and removes active classes
# Created: October 21, 2025

Write-Host "Fixing mobile navigation highlighting across all pages..." -ForegroundColor Green

# Get all HTML files
$files = Get-ChildItem -Filter "*.html"

$updatedCount = 0

foreach ($file in $files) {
    try {
        Write-Host "Processing $($file.Name)..." -ForegroundColor Yellow
        
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        
        # Fix 1: Reduce default background opacity
        $oldBackground = "background: rgba(161, 196, 79, 0.3) !important;"
        $newBackground = "background: rgba(161, 196, 79, 0.1) !important;"
        $content = $content -replace [regex]::Escape($oldBackground), $newBackground
        
        # Fix 2: Reduce default border opacity  
        $oldBorder = "border: 2px solid rgba(161, 196, 79, 0.6) !important;"
        $newBorder = "border: 2px solid rgba(161, 196, 79, 0.3) !important;"
        $content = $content -replace [regex]::Escape($oldBorder), $newBorder
        
        # Fix 3: Reduce default shadow
        $oldShadow = "box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);"
        $newShadow = "box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);"
        $content = $content -replace [regex]::Escape($oldShadow), $newShadow
        
        # Fix 4: Remove active classes from navigation links
        $content = $content -replace 'class="nav-link active"', 'class="nav-link"'
        
        # Check if any changes were made
        if ($content -ne $originalContent) {
            Set-Content $file.FullName -Value $content -Encoding UTF8
            $updatedCount++
            Write-Host "  Updated $($file.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "  No changes needed for $($file.Name)" -ForegroundColor Gray
        }
        
    }
    catch {
        Write-Host "  Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Mobile navigation highlighting fix completed!" -ForegroundColor Green
Write-Host "Files updated: $updatedCount" -ForegroundColor Cyan
Write-Host "Navigation will now only highlight on hover, not by default" -ForegroundColor Yellow