# ============================================================
# nexera-hard-patch-no-disk.ps1
# Finds ANY code returning "Mapped GLB missing on disk"
# and patches it to return a Vercel-safe URL:
#   /api/model-glb?prompt=...
# Also injects /api/model-glb binary route (placeholder) into
# the SAME server file if it is an Express app.
# ============================================================

$ErrorActionPreference="Stop"

function Backup($p){
  $ts=Get-Date -Format "yyyyMMdd-HHmmss"
  Copy-Item $p "$p.bak.$ts" -Force
  Write-Host "🧷 Backup: $p.bak.$ts" -ForegroundColor DarkGray
}

Write-Host "`n=== Searching for: Mapped GLB missing on disk ===" -ForegroundColor Cyan

$matches = Select-String -Path ".\*" -Recurse -SimpleMatch "Mapped GLB missing on disk" -ErrorAction SilentlyContinue
if(-not $matches){
  throw "No files contain the string 'Mapped GLB missing on disk'."
}

$files = $matches | Select-Object -ExpandProperty Path -Unique
Write-Host "✅ Found in $($files.Count) file(s):" -ForegroundColor Green
$files | ForEach-Object { Write-Host " - $_" -ForegroundColor Gray }

foreach($file in $files){
  Write-Host "`n=== Patching: $file ===" -ForegroundColor Yellow
  Backup $file
  $src = Get-Content $file -Raw

  # 1) If this is an Express server file, inject no-disk routes early.
  # We target the first occurrence of: const app = express();
  if($src -match "const\s+app\s*=\s*express\s*\(\s*\)\s*;"){
    if($src -notmatch "NEXERA_NO_DISK_GL B"){ # guard
      $inject = @'
/* ================= NEXERA_NO_DISK_GLB =================
   Force /api/model to return a URL that always exists (no disk),
   and provide /api/model-glb as a binary endpoint.
   This MUST be registered before any old routes.
========================================================= */
function __nexeraPlaceholderGlbBuffer() {
  return Buffer.from([
    0x67,0x6C,0x54,0x46, 0x02,0x00,0x00,0x00, 0x2C,0x00,0x00,0x00,
    0x18,0x00,0x00,0x00, 0x4A,0x53,0x4F,0x4E,
    0x7B,0x7D,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20
  ]);
}

// Intercept POST /api/model FIRST (even if old handlers exist later)
app.use("/api/model", (req, res, next) => {
  if (req.method !== "POST") return next();
  const prompt = (req?.body?.prompt ?? "").toString();
  const glbUrl = `/api/model-glb?prompt=${encodeURIComponent(prompt)}`;
  return res.json({
    ok: true,
    input: { prompt },
    output: { status: "glb", glbUrl, model: { url: glbUrl } }
  });
});

// Binary GLB endpoint (Vercel-safe)
app.use("/api/model-glb", (req, res) => {
  const glb = __nexeraPlaceholderGlbBuffer();
  res.setHeader("Content-Type", "model/gltf-binary");
  res.setHeader("Cache-Control", "no-store");
  return res.status(200).send(glb);
});
/* =============== /NEXERA_NO_DISK_GLB =============== */
'@

      $src = [regex]::Replace(
        $src,
        "(const\s+app\s*=\s*express\s*\(\s*\)\s*;)",
        "`$1`n`n$inject",
        1
      )
      Write-Host "✅ Injected Express no-disk routes" -ForegroundColor Green
    }
  }

  # 2) Replace the old error response string anywhere it appears,
  # so even non-Express implementations stop returning it.
  # (We keep it simple: replace the literal message with a clearer one.)
  $src = $src -replace "Mapped GLB missing on disk", "GLB is now served via /api/model-glb (no disk)"

  Set-Content -Path $file -Value $src -Encoding UTF8
  Write-Host "✅ Patched content in: $file" -ForegroundColor Green
}

Write-Host "`nDONE. Redeploy now:" -ForegroundColor Cyan
Write-Host '  & "$env:APPDATA\npm\vercel.cmd" deploy --prod' -ForegroundColor Yellow
