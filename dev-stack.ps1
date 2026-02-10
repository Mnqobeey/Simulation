# ============================================================
# dev-stack.ps1
# START / STOP / STATUS with verification (API 3005, UI 5173)
# ============================================================

param(
  [switch]$Start,
  [switch]$Stop,
  [switch]$Status,
  [string]$ProjectPath = "C:\Projects\nexera-text-to-3d"
)

$ports = @(3005,5173,5174,5175)

function Assert-ProjectRoot {
  if (-not (Test-Path $ProjectPath)) { throw "Project path not found: $ProjectPath" }
  Set-Location $ProjectPath
  if (-not (Test-Path ".\package.json")) { throw "package.json not found in $ProjectPath" }
}

function Get-ListeningProcIdsOnPort([int]$port) {
  $procIds = @()
  $lines = netstat -ano | Select-String "LISTENING" | Select-String ":$port\s"
  foreach ($line in $lines) {
    $parts = ($line -split "\s+") | Where-Object { $_ -ne "" }
    $procId = $parts[-1]
    if ($procId -match "^\d+$") { $procIds += [int]$procId }
  }
  $procIds | Select-Object -Unique
}

function Kill-Port([int]$port) {
  foreach ($procId in (Get-ListeningProcIdsOnPort $port)) {
    try {
      $p = Get-Process -Id $procId -ErrorAction Stop
      Write-Host "Killing PID $procId ($($p.ProcessName)) on port $port" -ForegroundColor Yellow
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    } catch {
      Write-Host "Could not kill PID $procId on port $port" -ForegroundColor DarkYellow
    }
  }
}

function Stop-DevStack {
  Write-Host "`n=== STOP: Freeing ports 3005/5173/5174/5175 ===" -ForegroundColor Cyan
  foreach ($p in $ports) { Kill-Port $p }
  Write-Host "✅ STOP complete." -ForegroundColor Green
}

function Show-Status {
  Write-Host "`n=== STATUS: Ports ===" -ForegroundColor Cyan
  foreach ($port in $ports) {
    $procId = (Get-ListeningProcIdsOnPort $port | Select-Object -First 1)
    if ($procId) {
      $name = "unknown"
      try { $name = (Get-Process -Id $procId -ErrorAction Stop).ProcessName } catch {}
      Write-Host ("Port {0} => LISTENING (PID {1}, {2})" -f $port,$procId,$name) -ForegroundColor Yellow
    } else {
      Write-Host ("Port {0} => free" -f $port) -ForegroundColor Green
    }
  }
}

function Wait-Port([int]$port, [int]$seconds=8) {
  $deadline = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $deadline) {
    if (Get-ListeningProcIdsOnPort $port) { return $true }
    Start-Sleep -Milliseconds 250
  }
  return $false
}

function Start-DevStack {
  Assert-ProjectRoot

  Write-Host "`n=== START: Clean boot (API=3005, UI=5173) ===" -ForegroundColor Cyan
  Stop-DevStack

  if (-not (Test-Path ".\server\index.mjs")) { throw "Missing server/index.mjs" }

  # Log files
  $logDir = Join-Path $ProjectPath ".logs"
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $apiLog = Join-Path $logDir "api.log"
  $uiLog  = Join-Path $logDir "ui.log"
  "" | Set-Content -Encoding UTF8 $apiLog
  "" | Set-Content -Encoding UTF8 $uiLog

  Write-Host "Starting API server -> http://localhost:3005" -ForegroundColor Yellow
  Start-Process powershell -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-Command","cd `"$ProjectPath`"; node server/index.mjs 2>&1 | Tee-Object -FilePath `"$apiLog`""

  if (-not (Wait-Port 3005 8)) {
    Write-Host "❌ API did not open port 3005. Check: $apiLog" -ForegroundColor Red
    return
  }

  Write-Host "Starting Vite UI -> http://localhost:5173" -ForegroundColor Yellow
  Start-Process powershell -ArgumentList "-NoExit","-ExecutionPolicy","Bypass","-Command","cd `"$ProjectPath`"; npx vite --port 5173 --strictPort 2>&1 | Tee-Object -FilePath `"$uiLog`""

  if (-not (Wait-Port 5173 10)) {
    Write-Host "`n❌ Vite did NOT open port 5173 (it probably crashed instantly)." -ForegroundColor Red
    Write-Host "Open the Vite window OR read the log: $uiLog" -ForegroundColor Yellow
    Write-Host "`nLast 40 lines of Vite log:" -ForegroundColor Cyan
    Get-Content $uiLog -Tail 40
    return
  }

  Write-Host "`n✅ START complete." -ForegroundColor Green
  Write-Host "UI   : http://localhost:5173/" -ForegroundColor Green
  Write-Host "API  : http://localhost:3005/api/model" -ForegroundColor Green
  Write-Host "Proxy: http://localhost:5173/api/model" -ForegroundColor Green
}

if (-not ($Start -or $Stop -or $Status)) {
  Write-Host "Usage:" -ForegroundColor Cyan
  Write-Host "  .\dev-stack.ps1 -Start" -ForegroundColor Gray
  Write-Host "  .\dev-stack.ps1 -Stop" -ForegroundColor Gray
  Write-Host "  .\dev-stack.ps1 -Status" -ForegroundColor Gray
  exit 0
}

try {
  if ($Stop)   { Stop-DevStack }
  if ($Status) { Show-Status }
  if ($Start)  { Start-DevStack }
} catch {
  Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
