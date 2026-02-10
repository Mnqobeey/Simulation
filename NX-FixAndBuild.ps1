param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK]   $m" -ForegroundColor Green }

$files = @(
  "index.html",
  "package.json",
  "vite.config.js",
  "src\main.js",
  "src\main-avatar.js",
  "src\avatarMode.js",
  "src\style.css",
  "style.css"
) | ForEach-Object { Join-Path $Root $_ }

function Sanitize-TextFile([string]$Path){
  if(!(Test-Path -LiteralPath $Path)){ return }

  Info "Sanitizing $Path"

  $full = (Resolve-Path -LiteralPath $Path).Path
  $bytes = [System.IO.File]::ReadAllBytes($full)

  # Remove UTF-8 BOM if present
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bytes = $bytes[3..($bytes.Length-1)]
  }

  $txt = [System.Text.Encoding]::UTF8.GetString($bytes)

  # Strip control characters including C1 controls (0x80-0x9F) that break parse5
  # Keep: tab(\x09), LF(\x0A), CR(\x0D)
  $txt = [regex]::Replace($txt, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]", "")

  # Remove Unicode replacement character using STRING overload (PS 5.1 safe)
  $txt = $txt.Replace([string][char]0xFFFD, "")

  # Write UTF-8 NO BOM
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($full, $txt, $utf8NoBom)
}

$files | ForEach-Object { Sanitize-TextFile $_ }

Ok "Sanitization done."
Info "Running npm run build..."
npm run build
Ok "Build complete."
