# Enterprise CSS & JavaScript Minification Script
Write-Host "Minifying CSS and JavaScript files..." -ForegroundColor Green

# Create minified directory
$minDir = "assets\min"
if (!(Test-Path $minDir)) {
    New-Item -ItemType Directory -Path $minDir -Force
    Write-Host "Created minified assets directory" -ForegroundColor Cyan
}

# CSS Minification Function
function Compress-CSS {
    param($inputFile, $outputFile)
    
    try {
        $content = Get-Content $inputFile -Raw
        
        # Remove comments
        $content = $content -replace '/\*[\s\S]*?\*/', ''
        
        # Remove unnecessary whitespace
        $content = $content -replace '\s+', ' '
        $content = $content -replace ';\s*}', '}'
        $content = $content -replace '{\s*', '{'
        $content = $content -replace '}\s*', '}'
        $content = $content -replace ':\s*', ':'
        $content = $content -replace ';\s*', ';'
        $content = $content.Trim()
        
        Set-Content -Path $outputFile -Value $content -NoNewline
        
        $originalSize = (Get-Item $inputFile).Length
        $minifiedSize = (Get-Item $outputFile).Length
        $savings = [math]::Round((($originalSize - $minifiedSize) / $originalSize) * 100, 1)
        
        Write-Host "Minified $(Split-Path $inputFile -Leaf) - Saved $savings%" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Failed to minify CSS: $inputFile" -ForegroundColor Red
    }
}

# JavaScript Minification Function  
function Compress-JS {
    param($inputFile, $outputFile)
    
    try {
        $content = Get-Content $inputFile -Raw
        
        # Remove single-line comments
        $content = $content -replace '(?<!:)//.*$', '', 'Multiline'
        
        # Remove multi-line comments
        $content = $content -replace '/\*[\s\S]*?\*/', ''
        
        # Remove unnecessary whitespace
        $content = $content -replace '\s+', ' '
        $content = $content -replace ';\s*', ';'
        $content = $content -replace '{\s*', '{'
        $content = $content -replace '}\s*', '}'
        $content = $content -replace ',\s*', ','
        $content = $content.Trim()
        
        Set-Content -Path $outputFile -Value $content -NoNewline
        
        $originalSize = (Get-Item $inputFile).Length
        $minifiedSize = (Get-Item $outputFile).Length
        $savings = [math]::Round((($originalSize - $minifiedSize) / $originalSize) * 100, 1)
        
        Write-Host "Minified $(Split-Path $inputFile -Leaf) - Saved $savings%" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Failed to minify JS: $inputFile" -ForegroundColor Red
    }
}

# Process CSS Files
Write-Host "Processing CSS Files..." -ForegroundColor Yellow
$cssFiles = Get-ChildItem -Path "css" -Filter "*.css"
foreach ($cssFile in $cssFiles) {
    $outputFile = Join-Path $minDir "$($cssFile.BaseName).min.css"
    Compress-CSS $cssFile.FullName $outputFile
}

# Process JavaScript Files
Write-Host "Processing JavaScript Files..." -ForegroundColor Yellow  
$jsFiles = Get-ChildItem -Path "js" -Filter "*.js"
foreach ($jsFile in $jsFiles) {
    $outputFile = Join-Path $minDir "$($jsFile.BaseName).min.js"
    Compress-JS $jsFile.FullName $outputFile
}

# Create Critical CSS
Write-Host "Creating Critical CSS..." -ForegroundColor Yellow
$criticalCSS = ":root{--primary-color:#A1C44F;--text-dark:#2C3E50;--white:#FFFFFF}*{margin:0;padding:0;box-sizing:border-box}body{font-family:Inter,sans-serif;line-height:1.6;color:var(--text-dark);background:var(--white)}.container{max-width:1200px;margin:0 auto;padding:0 20px}.header{background:var(--white);position:fixed;width:100%;top:0;z-index:1000}.logo img{height:40px;width:auto}.hero{height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;color:var(--white)}.btn{display:inline-block;padding:12px 30px;background:var(--primary-color);color:var(--white);text-decoration:none;border-radius:5px}"

Set-Content -Path "$minDir\critical.min.css" -Value $criticalCSS -NoNewline
Write-Host "Critical CSS created" -ForegroundColor Green

Write-Host "CSS & JavaScript minification complete!" -ForegroundColor Green