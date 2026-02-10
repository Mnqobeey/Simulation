Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "[FAIL] $m" -ForegroundColor Red; throw $m }

if(-not (Test-Path ".\package.json")){ Fail "Run this from your project root (where package.json exists)." }
if(-not (Test-Path ".\src")){ Fail "Missing .\src folder." }
if(-not (Test-Path ".\index.html")){ Fail "Missing index.html in project root." }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

# -----------------------------
# 1) Create/overwrite src/entry.js (NO top-level await)
# -----------------------------
if(Test-Path ".\src\entry.js"){
  Copy-Item ".\src\entry.js" ".\src\entry.backup.$stamp.js" -Force
  Ok "Backup: src/entry.js -> src/entry.backup.$stamp.js"
}

$entryJs = @"
/**
 * Single production-safe entry point.
 * NO top-level await (works with Vite target es2020 / older browsers).
 */
(function () {
  const params = new URLSearchParams(location.search);
  const mode = params.get("mode") || "";

  const boot = async () => {
    try {
      if (!mode) {
        await import("./landing-3d.js");
      } else if (mode === "avatar") {
        await import("./main-avatar.js");
      } else {
        await import("./main.js");
      }
    } catch (e) {
      const msg = (e && e.message) ? e.message : String(e);
      document.body.innerHTML =
        '<pre style="white-space:pre-wrap;padding:16px;color:#fff;background:#0b0f1a">' +
        'BOOT ERROR:\n' + msg + '\n</pre>';
      console.error(e);
    }
  };

  boot();
})();
"@

Set-Content -LiteralPath ".\src\entry.js" -Value $entryJs -Encoding UTF8
Ok "Wrote src/entry.js"

# -----------------------------
# 2) Fix src/main-avatar.js top-level await (wrap non-import code)
# -----------------------------
if(-not (Test-Path ".\src\main-avatar.js")){ Fail "src/main-avatar.js not found." }

Copy-Item ".\src\main-avatar.js" ".\src\main-avatar.backup.$stamp.js" -Force
Ok "Backup: src/main-avatar.js -> src/main-avatar.backup.$stamp.js"

$content = Get-Content -LiteralPath ".\src\main-avatar.js" -Raw

if($content -match "NEXERA_NO_TLA_WRAPPER"){
  Warn "src/main-avatar.js already wrapped (NEXERA_NO_TLA_WRAPPER found). Skipping."
} else {
  $lines = $content -split "`r?`n"
  $importLines = New-Object System.Collections.Generic.List[string]
  $restLines   = New-Object System.Collections.Generic.List[string]

  $state = "imports"
  foreach($ln in $lines){
    $trim = $ln.Trim()
    if($state -eq "imports"){
      if(
        $trim -eq "" -or
        $trim.StartsWith("//") -or
        $trim.StartsWith("/*") -or
        $trim.StartsWith("*") -or
        $trim.StartsWith("*/") -or
        $trim.StartsWith("import ")
      ){
        $importLines.Add($ln) | Out-Null
      } else {
        $state = "rest"
        $restLines.Add($ln) | Out-Null
      }
    } else {
      $restLines.Add($ln) | Out-Null
    }
  }

  $imports = ($importLines -join "`r`n").TrimEnd()
  $rest    = ($restLines   -join "`r`n").Trim()

  $wrapped = $imports + "`r`n`r`n" +
@"
// NEXERA_NO_TLA_WRAPPER: prevents top-level await build errors
(function () {
  const bootAvatar = async () => {
$rest
  };

  bootAvatar().catch((e) => {
    const msg = (e && e.message) ? e.message : String(e);
    document.body.innerHTML =
      '<pre style="white-space:pre-wrap;padding:16px;color:#fff;background:#0b0f1a">' +
      'AVATAR BOOT ERROR:\n' + msg + '\n</pre>';
    console.error(e);
  });
})();
"@

  Set-Content -LiteralPath ".\src\main-avatar.js" -Value $wrapped -Encoding UTF8
  Ok "Wrapped src/main-avatar.js (removed top-level await)"
}

# -----------------------------
# 3) Ensure index.html uses /src/entry.js (and NOT direct /src/main.js imports)
# -----------------------------
Copy-Item ".\index.html" ".\index.backup.$stamp.html" -Force
Ok "Backup: index.html -> index.backup.$stamp.html"

$html = Get-Content -LiteralPath ".\index.html" -Raw

# Replace an existing ROUTING block if present:
$patternRoutingBlock = '(?s)<!--\s*ROUTING\s*-->.*?<script\s+type="module">.*?</script>'
$routingReplacement = "<!-- ROUTING -->`n<script type=`"module`">`n  import `"/src/entry.js`";`n</script>"

if($html -match $patternRoutingBlock){
  $html = [regex]::Replace($html, $patternRoutingBlock, $routingReplacement)
  Ok "Replaced ROUTING block to use /src/entry.js"
} else {
  # Remove any old module scripts that import main/main-avatar/landing directly
  $html = [regex]::Replace(
    $html,
    '(?s)<script\s+type="module">.*?(\/src\/(main|main-avatar|landing-3d)\.js).*?</script>',
    ''
  )

  if($html -notmatch '\/src\/entry\.js'){
    # Inject before </body>
    $inject = "`n<script type=`"module`">`n  import `"/src/entry.js`";`n</script>`n"
    $html = $html -replace '</body>', ($inject + '</body>')
    Ok "Injected /src/entry.js before </body>"
  } else {
    Warn "index.html already references /src/entry.js"
  }
}

Set-Content -LiteralPath ".\index.html" -Value $html -Encoding UTF8
Ok "Wrote index.html"

# -----------------------------
# 4) Clean dist and build
# -----------------------------
if(Test-Path ".\dist"){
  Remove-Item ".\dist" -Recurse -Force
  Ok "Removed dist/"
}

Info "Running: npm run build"
npm run build
if($LASTEXITCODE -ne 0){ Fail "Build failed." }
Ok "Build succeeded."

Info "Next: npm run preview"
Info "Test: / , /?mode=asset , /?mode=avatar"
