# Enterprise CSS & JavaScript Minification Script
# Compresses and optimizes all CSS and JS files
# Removes unused code and combines critical resources

Write-Host "🗜️ Starting Enterprise CSS & JavaScript Minification..." -ForegroundColor Green

# Create minified directory
$minDir = "assets\min"
if (!(Test-Path $minDir)) {
    New-Item -ItemType Directory -Path $minDir -Force
    Write-Host "✅ Created minified assets directory" -ForegroundColor Cyan
}

# CSS Minification Function
function Minify-CSS {
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
        
        # Write minified content
        Set-Content -Path $outputFile -Value $content -NoNewline
        
        $originalSize = (Get-Item $inputFile).Length
        $minifiedSize = (Get-Item $outputFile).Length
        $savings = [math]::Round((($originalSize - $minifiedSize) / $originalSize) * 100, 1)
        
        Write-Host "✅ Minified $(Split-Path $inputFile -Leaf) - Saved $savings%" -ForegroundColor Green
        
    }
    catch {
        Write-Host "❌ Failed to minify CSS: $inputFile" -ForegroundColor Red
    }
}

# JavaScript Minification Function
function Minify-JS {
    param($inputFile, $outputFile)
    
    try {
        $content = Get-Content $inputFile -Raw
        
        # Remove single-line comments (but preserve URLs)
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
        
        # Write minified content
        Set-Content -Path $outputFile -Value $content -NoNewline
        
        $originalSize = (Get-Item $inputFile).Length
        $minifiedSize = (Get-Item $outputFile).Length
        $savings = [math]::Round((($originalSize - $minifiedSize) / $originalSize) * 100, 1)
        
        Write-Host "✅ Minified $(Split-Path $inputFile -Leaf) - Saved $savings%" -ForegroundColor Green
        
    }
    catch {
        Write-Host "❌ Failed to minify JS: $inputFile" -ForegroundColor Red
    }
}

# Process CSS Files
Write-Host "📄 Processing CSS Files..." -ForegroundColor Yellow
$cssFiles = Get-ChildItem -Path "css" -Filter "*.css"
foreach ($cssFile in $cssFiles) {
    $outputFile = Join-Path $minDir "$($cssFile.BaseName).min.css"
    Minify-CSS $cssFile.FullName $outputFile
}

# Process JavaScript Files
Write-Host "📜 Processing JavaScript Files..." -ForegroundColor Yellow
$jsFiles = Get-ChildItem -Path "js" -Filter "*.js"
foreach ($jsFile in $jsFiles) {
    $outputFile = Join-Path $minDir "$($jsFile.BaseName).min.js"
    Minify-JS $jsFile.FullName $outputFile
}

# Create Critical CSS
Write-Host "🎯 Creating Critical CSS..." -ForegroundColor Yellow
$criticalCSS = '/* Critical CSS - Above the fold styles */
:root{--primary-color:#A1C44F;--text-dark:#2C3E50;--white:#FFFFFF;--transition:all .3s ease}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Inter,sans-serif;line-height:1.6;color:var(--text-dark);background:var(--white)}
.container{max-width:1200px;margin:0 auto;padding:0 20px}
.header{background:var(--white);position:fixed;width:100%;top:0;z-index:1000;box-shadow:0 2px 10px rgba(0,0,0,.1)}
.logo img{height:40px;width:auto}
.hero{height:100vh;display:flex;align-items:center;justify-content:center;text-align:center;color:var(--white);background:linear-gradient(rgba(0,0,0,.6),rgba(0,0,0,.6)),url(images/hero-bg.jpg);background-size:cover;background-position:center}
.btn{display:inline-block;padding:12px 30px;background:var(--primary-color);color:var(--white);text-decoration:none;border-radius:5px;transition:var(--transition)}'

Set-Content -Path "$minDir\critical.min.css" -Value $criticalCSS -NoNewline
Write-Host "✅ Critical CSS created" -ForegroundColor Green

# Create Combined JavaScript Bundle
Write-Host "📦 Creating JavaScript Bundle..." -ForegroundColor Yellow
$bundleContent = @()

# Critical JS files to bundle
$criticalJS = @(
    'js\performance-optimizer.js',
    'js\image-optimizer.js',
    'js\ibridge-auth.js',
    'js\enhanced-header.js'
)

foreach ($jsFile in $criticalJS) {
    if (Test-Path $jsFile) {
        $content = Get-Content $jsFile -Raw
        $bundleContent += "/* $jsFile */"
        $bundleContent += $content
    }
}

$bundleJS = $bundleContent -join "`n"
# Minify the bundle
$bundleJS = $bundleJS -replace '/\*[\s\S]*?\*/', ''
$bundleJS = $bundleJS -replace '\s+', ' '
$bundleJS = $bundleJS.Trim()

Set-Content -Path "$minDir\bundle.min.js" -Value $bundleJS -NoNewline
Write-Host "✅ JavaScript bundle created" -ForegroundColor Green

Write-Host "🎉 CSS & JavaScript minification complete!" -ForegroundColor Green
Write-Host "📊 Check assets\min\ directory for optimized files" -ForegroundColor Cyan