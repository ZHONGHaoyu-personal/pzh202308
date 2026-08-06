param([string]$Root)
if (-not $Root) { $Root = $PSScriptRoot }
$port = 8765
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Output "Serving $Root at http://localhost:$port/"
$mime = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8'; '.png'='image/png'; '.jpg'='image/jpeg'; '.woff2'='font/woff2'; '.ttf'='font/ttf'; '.mp3'='audio/mpeg'; '.svg'='image/svg+xml' }
while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $url = $ctx.Request.Url.AbsolutePath
        if ($url -eq '/' -or $url -eq '') { $url = '/index.html' }
        $rel = $url.TrimStart('/')
        $path = Join-Path $Root $rel
        if (Test-Path $path -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($path)
            $ct = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $ctx.Response.ContentType = $ct
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found: ' + $rel)
            $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $ctx.Response.Close()
    } catch {
        try { $ctx.Response.Close() } catch {}
        continue
    }
}
