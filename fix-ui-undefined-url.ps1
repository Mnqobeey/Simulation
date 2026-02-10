# ============================================================
# fix-ui-undefined-url.ps1
# Fixes deployed UI fetching /undefined by:
# - Using output.glbUrl OR output.model.url
# - Normalizing relative URLs to absolute URLs
# - Avoiding cache-busting on undefined URLs
# ============================================================

$ErrorActionPreference="Stop"

function Backup($p){
  if(Test-Path $p){
    $ts=Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak.$ts" -Force
    Write-Host "🧷 Backup: $p.bak.$ts" -ForegroundColor DarkGray
  }
}

$root = (Get-Location).Path
$main = Join-Path $root "src\main.js"
if(!(Test-Path $main)){ throw "src/main.js not found at: $main" }

Backup $main
$txt = Get-Content $main -Raw

# 1) Inject URL normalizer helper once (near top)
if($txt -notmatch "function\s+__nexeraNormalizeUrl"){
  $helper = @'
function __nexeraNormalizeUrl(u) {
  if (!u) return null;
  try {
    // If already absolute
    if (typeof u === "string" && /^https?:\/\//i.test(u)) return u;
    // Make relative URL absolute
    return new URL(u, window.location.origin).toString();
  } catch {
    return null;
  }
}

function __nexeraPickGlbUrl(data) {
  const u =
    (data && data.output && data.output.glbUrl) ||
    (data && data.output && data.output.model && data.output.model.url) ||
    (data && data.output && data.output.modelUrl) ||
    (data && data.model && data.model.url) ||
    null;
  return __nexeraNormalizeUrl(u);
}
'@

  # Insert after first line (works even if imports exist)
  $txt = [regex]::Replace($txt, '^(.*\r?\n)', "`$1`n$helper`n", 1)
  Write-Host "✅ Injected URL helper functions" -ForegroundColor Green
} else {
  Write-Host "ℹ️ URL helpers already present" -ForegroundColor Gray
}

# 2) Replace direct usage of data.output.model.url with a safer picker
# This prevents undefined when model is missing or renamed.
$txt = $txt -replace 'data\.output\.model\.url', '(__nexeraPickGlbUrl(data) || (data && data.output && data.output.model && data.output.model.url))'

# 3) Replace direct usage of output.model.url (in case code uses output var)
$txt = $txt -replace 'output\.model\.url', '(output.glbUrl || (output.model && output.model.url))'

# 4) If code has a "url =" assignment from response, force it through picker
# Best-effort: find "const url =" or "let url =" and wrap RHS if it references output/model
$txt = [regex]::Replace(
  $txt,
  '(\b(const|let)\s+([a-zA-Z0-9_]*url[a-zA-Z0-9_]*)\s*=\s*)([^;]+);',
  {
    param($m)
    $lhs = $m.Groups[1].Value
    $rhs = $m.Groups[4].Value
    if($rhs -match 'output\.glbUrl|output\.model|data\.output'){
      return "$lhs(__nexeraNormalizeUrl($rhs) || __nexeraPickGlbUrl(data));"
    }
    return $m.Value
  },
  3
)

# 5) If code appends cache-busting "?v=" onto a variable, ensure it doesn't do it when null
# Replace occurrences of `${something}?v=` patterns in a simple safe way (best-effort)
$txt = $txt -replace '\$\{([a-zA-Z0-9_]+)\}\?v=', '${$1 || ""}?v='

Set-Content -Path $main -Value $txt -Encoding UTF8
Write-Host "✅ Patched src/main.js to stop fetching /undefined" -ForegroundColor Green

Write-Host ""
Write-Host "NEXT:" -ForegroundColor Cyan
Write-Host "1) npm run dev (optional local check)" -ForegroundColor Gray
Write-Host "2) Redeploy:  & `"$env:APPDATA\npm\vercel.cmd`" deploy --prod" -ForegroundColor Gray
