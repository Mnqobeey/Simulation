# ============================================================
# fix-bom-and-redeploy.ps1
# Removes UTF-8 BOM from JSON files that Vercel/API parses,
# then redeploys.
# ============================================================

param(
  [string]$ProjectPath = "C:\Projects\nexera-text-to-3d"
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectPath

function Fix-Utf8NoBom([string]$path) {
  if (-not (Test-Path $path)) {
    Write-Host "Skip (missing): $path" -ForegroundColor DarkYellow
    return
  }

  $full = (Resolve-Path $path).Path
  $bytes = [System.IO.File]::ReadAllBytes($full)

  # Remove UTF-8 BOM bytes EF BB BF if present
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bytes = $bytes[3..($bytes.Length-1)]
  }

  $text = [System.Text.Encoding]::UTF8.GetString($bytes)

  # Also remove BOM char if present as first character
  if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
    $text = $text.Substring(1)
  }

  [System.IO.File]::WriteAllText($full, $text, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "✅ Fixed UTF-8 (no BOM): $path" -ForegroundColor Green
}

Write-Host "`n=== Removing BOM from critical JSON files ===" -ForegroundColor Cyan

# Files Vercel definitely reads
Fix-Utf8NoBom ".\package.json"
Fix-Utf8NoBom ".\vercel.json"

# Files your API/library selector likely reads
Fix-Utf8NoBom ".\public\assets\library\index.json"
Fix-Utf8NoBom ".\assets\library\index.json"

# If you have any other json configs, fix them too (best-effort)
Get-ChildItem -Recurse -Filter *.json |
  Where-Object { $_.FullName -like "*\public\assets\library\*" -or $_.Name -in @("package.json","vercel.json") } |
  ForEach-Object { Fix-Utf8NoBom $_.FullName }

Write-Host "`n=== Sanity checks (must pass) ===" -ForegroundColor Cyan

node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('✅ package.json parses in Node')"
node -e "JSON.parse(require('fs').readFileSync('vercel.json','utf8')); console.log('✅ vercel.json parses in Node')"

if (Test-Path ".\public\assets\library\index.json") {
  node -e "JSON.parse(require('fs').readFileSync('public/assets/library/index.json','utf8')); console.log('✅ public/assets/library/index.json parses in Node')"
}
if (Test-Path ".\assets\library\index.json") {
  node -e "JSON.parse(require('fs').readFileSync('assets/library/index.json','utf8')); console.log('✅ assets/library/index.json parses in Node')"
}

Write-Host "`n=== Redeploying to Vercel ===" -ForegroundColor Cyan
vercel --prod

Write-Host "`n✅ Done. Now test production:" -ForegroundColor Green
Write-Host "  irm https://nexera-text-to-3d.vercel.app/api/health -Method Get" -ForegroundColor Gray
Write-Host "  irm https://nexera-text-to-3d.vercel.app/api/model -Method Post -ContentType 'application/json' -Body '{\"prompt\":\"blue sphere\"}'" -ForegroundColor Gray
