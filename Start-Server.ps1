# Simple HTTP Server for iBridge Website
$port = 8080
$root = $PSScriptRoot

Write-Host "Starting iBridge Local Server..." -ForegroundColor Cyan
Write-Host "Root Directory: $root" -ForegroundColor Yellow
Write-Host "Server URL: http://localhost:$port" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Server started successfully on port $port" -ForegroundColor Green
Write-Host ""

$mimeTypes = @{
    '.html' = 'text/html'
    '.css' = 'text/css'
    '.js' = 'application/javascript'
    '.json' = 'application/json'
    '.png' = 'image/png'
    '.jpg' = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif' = 'image/gif'
    '.svg' = 'image/svg+xml'
    '.ico' = 'image/x-icon'
    '.woff' = 'font/woff'
    '.woff2' = 'font/woff2'
    '.ttf' = 'font/ttf'
    '.eot' = 'application/vnd.ms-fontobject'
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        if ($path -eq '/') { $path = '/index.html' }
        
        $filePath = Join-Path $root $path.TrimStart('/')
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $($request.HttpMethod) $path" -NoNewline
        
        if (Test-Path $filePath -PathType Leaf) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            
            if ($mimeTypes.ContainsKey($extension)) {
                $response.ContentType = $mimeTypes[$extension]
            } else {
                $response.ContentType = 'application/octet-stream'
            }
            
            $response.ContentLength64 = $content.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($content, 0, $content.Length)
            
            Write-Host " → 200 OK ($($content.Length) bytes)" -ForegroundColor Green
        }
        else {
            $response.StatusCode = 404
            $html = "<html><body><h1>404 - File Not Found</h1><p>$path</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = 'text/html'
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            
            Write-Host " → 404 Not Found" -ForegroundColor Red
        }
        
        $response.Close()
    }
}
finally {
    $listener.Stop()
    Write-Host "`nServer stopped." -ForegroundColor Yellow
}
