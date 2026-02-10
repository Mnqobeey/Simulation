$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Fail($m){ Write-Host "[FAIL] $m" -ForegroundColor Red; throw $m }

# --- Helpers ---
function Backup-File([string]$Path){
  if(Test-Path $Path){
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $Path "$Path.backup.$stamp" -Force
    Ok "Backup: $Path.backup.$stamp"
  }
}

function Write-UTF8NoBOM([string]$Path, [string]$Content){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path $Path -Parent)).Path + "\" + (Split-Path $Path -Leaf), $Content, $utf8NoBom)
}

Info "1) Backups"
Backup-File ".\index.html"
Backup-File ".\vercel.json"
Backup-File ".\src\entry.js"
Backup-File ".\src\main-avatar.js"

Info "2) Write src/entry.js (NO top-level await)"
$entry = @'
(function () {
  const qs = new URLSearchParams(location.search);
  const mode = qs.get("mode") || "";

  // Never use top-level await (esbuild target blocks it)
  const run = async () => {
    try {
      if (!mode) {
        await import("./landing-3d.js");
        return;
      }
      if (mode === "avatar") {
        await import("./main-avatar.js");
        return;
      }
      await import("./main.js");
    } catch (e) {
      const msg = (e && e.message) ? e.message : String(e);
      document.body.innerHTML =
        "<pre style='white-space:pre-wrap;padding:16px;color:#fff;background:#0b0f1a'>ENTRY ERROR:\n" +
        msg + "\n</pre>";
      console.error(e);
    }
  };

  run();
})();
'@
if(!(Test-Path ".\src")){ New-Item -ItemType Directory ".\src" | Out-Null }
Write-UTF8NoBOM ".\src\entry.js" $entry
Ok "Wrote src/entry.js"

Info "3) Patch index.html to use entry.js (single safe router)"
if(!(Test-Path ".\index.html")){ Fail "index.html not found in project root" }
$html = Get-Content -Raw -LiteralPath ".\index.html"

# Replace ANY routing module script (your old ROUTING block) with a simple module include
# We look for the marker "<!-- ROUTING -->" and replace the next script tag(s) until the next comment or end.
$pattern = '(?s)<!--\s*ROUTING\s*-->.*?(<script[^>]*type\s*=\s*"module"[^>]*>.*?</script>|<script[^>]*type\s*=\s*"module"[^>]*src\s*=\s*".*?"[^>]*>\s*</script>)'
$replacement = @'
<!-- ROUTING -->
<script type="module" src="/src/entry.js"></script>
'@

if($html -match $pattern){
  $html = [regex]::Replace($html, $pattern, $replacement)
  Ok "Replaced ROUTING block"
} else {
  # If no marker found, append safely before </body>
  $html = $html -replace '(?i)</body>', "$replacement`n</body>"
  Ok "Inserted ROUTING block before </body>"
}

Write-UTF8NoBOM ".\index.html" $html
Ok "Patched index.html"

Info "4) Fix src/main-avatar.js by forcing NO top-level await + removing stray partial wrappers"
$avatarPath = ".\src\main-avatar.js"
if(!(Test-Path $avatarPath)){
  Fail "src/main-avatar.js not found"
}

$avatar = Get-Content -Raw -LiteralPath $avatarPath

# If file already contains an IIFE wrapper marker, don’t double-wrap. Otherwise wrap the whole module.
if($avatar -notmatch 'NEXERA_NO_TLA_WRAPPER'){
  $wrapped = @"
import { initAvatarMode } from "./avatarMode.js";

/* NEXERA_NO_TLA_WRAPPER
   This file is wrapped to avoid top-level await build failures.
*/
(function () {
  const bootAvatar = async () => {
$avatar

  };

  bootAvatar().catch((e) => {
    const msg = (e && e.message) ? e.message : String(e);
    document.body.innerHTML =
      "<pre style='white-space:pre-wrap;padding:16px;color:#fff;background:#0b0f1a'>AVATAR BOOT ERROR:\n" +
      msg + "\n</pre>";
    console.error(e);
  });
})();
"@

  # Remove duplicate init import if present in original file to avoid "Identifier already declared"
  $wrapped = $wrapped -replace '(?m)^\s*import\s+\{\s*initAvatarMode\s*\}\s+from\s+["'']\.\/avatarMode\.js["''];\s*\r?\n', ''

  Write-UTF8NoBOM $avatarPath $wrapped
  Ok "Wrapped src/main-avatar.js to remove top-level await"
} else {
  Ok "src/main-avatar.js already wrapped"
}

Info "5) Write a CLEAN vercel.json (no broken rewrites, no assets->api)"
# Vercel already routes /api/* to serverless functions automatically if you have /api directory.
# For SPA routing we only rewrite non-file routes to index.html.
$vercel = @'
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "rewrites": [
    { "source": "/((?!assets/|favicon.ico|robots.txt|sitemap.xml|api/).*)", "destination": "/index.html" }
  ]
}
'@
Write-UTF8NoBOM ".\vercel.json" $vercel
Ok "Wrote vercel.json"

Info "6) Hard clean + install + build"
if(Test-Path ".\dist"){ Remove-Item ".\dist" -Recurse -Force }
if(Test-Path ".\node_modules\.vite"){ Remove-Item ".\node_modules\.vite" -Recurse -Force }
npm install | Out-Host
npm run build | Out-Host

if(!(Test-Path ".\dist\index.html")){ Fail "dist/index.html missing after build" }
Ok "Build produced dist/index.html"

Info "7) Verify dist/index.html references only existing /assets/*"
$distHtml = Get-Content -Raw -LiteralPath ".\dist\index.html"
$matches = [regex]::Matches($distHtml, '\/assets\/[A-Za-z0-9._-]+\.(?:js|css|woff2|png|svg|webp|jpg|jpeg|gif)')
$unique = New-Object System.Collections.Generic.HashSet[string]
foreach($m in $matches){ [void]$unique.Add($m.Value) }

if($unique.Count -eq 0){ Fail "No /assets/* refs found in dist/index.html (unexpected build output)" }

$missing = @()
foreach($p in $unique){
  $disk = Join-Path ".\dist" ($p.TrimStart("/") -replace "/", "\")
  if(!(Test-Path $disk)){ $missing += $p }
}
if($missing.Count -gt 0){
  Write-Host "Missing assets:" -ForegroundColor Yellow
  $missing | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
  Fail "Asset mismatch => preview/deploy blank"
}
Ok "All referenced assets exist."

Info "DONE. Now run: npm run preview (and then deploy)"
Ok "Preview URL will be: http://localhost:4173"
