param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'Website'
$deployRoot = Join-Path $repoRoot 'Deployment/main-site'

$publicPages = @(
    'index.html',
    'about.html',
    'services.html',
    'team.html',
    'careers.html',
    'contact.html',
    'privacy.html',
    'cookie-notice.html',
    'compliance.html',
    'terms.html',
    'accessibility.html',
    'security-policy.html',
    'staff-login.html',
    'contact-center.html',
    'contact-center-solutions.html',
    'it-support.html',
    'it-support-services.html',
    'ai-automation.html',
    'business-process-outsourcing.html',
    'client-interaction.html',
    'offline.html',
    '404.html',
    '.htaccess',
    'robots.txt',
    'security.txt',
    'sitemap.xml',
    'manifest.json'
)

$publicDirectories = @(
    'css',
    'js',
    'images',
    '.well-known'
)

$excludedImageDirectories = @(
    'generated-hq\backup-before-enhance',
    'generated-variants'
)

if (-not (Test-Path $deployRoot)) {
    New-Item -ItemType Directory -Path $deployRoot | Out-Null
}

if ($Clean) {
    foreach ($page in $publicPages) {
        $target = Join-Path $deployRoot $page
        if (Test-Path $target) {
            Remove-Item $target -Force -Recurse
        }
    }

    foreach ($directory in $publicDirectories) {
        $target = Join-Path $deployRoot $directory
        if (Test-Path $target) {
            Remove-Item $target -Force -Recurse
        }
    }
}

foreach ($page in $publicPages) {
    $sourcePath = Join-Path $sourceRoot $page
    $targetPath = Join-Path $deployRoot $page
    if (Test-Path $sourcePath) {
        $targetDirectory = Split-Path -Parent $targetPath
        if ($targetDirectory -and -not (Test-Path $targetDirectory)) {
            New-Item -ItemType Directory -Path $targetDirectory | Out-Null
        }
        Copy-Item $sourcePath $targetPath -Force
    }
}

foreach ($directory in $publicDirectories) {
    $sourcePath = Join-Path $sourceRoot $directory
    $targetPath = Join-Path $deployRoot $directory
    if (Test-Path $sourcePath) {
        if (Test-Path $targetPath) {
            Remove-Item $targetPath -Recurse -Force
        }
        Copy-Item $sourcePath $targetPath -Recurse -Force
    }
}

$deployImagesRoot = Join-Path $deployRoot 'images'
foreach ($relativeDirectory in $excludedImageDirectories) {
    $targetPath = Join-Path $deployImagesRoot $relativeDirectory
    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
}

Write-Host "Public site synced from $sourceRoot to $deployRoot"
