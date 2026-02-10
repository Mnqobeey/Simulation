param([switch]$Prod = $true)

$ErrorActionPreference = "Stop"

function Pause-Shell {
  Write-Host ""
  Write-Host "===========================================================" -ForegroundColor Yellow
  Write-Host "PRESS ENTER TO CLOSE" -ForegroundColor Yellow
  Write-Host "===========================================================" -ForegroundColor Yellow
  Read-Host | Out-Null
}

function Title([string]$msg){
  Write-Host ""
  Write-Host "===========================================================" -ForegroundColor Cyan
  Write-Host $msg -ForegroundColor Cyan
  Write-Host "===========================================================" -ForegroundColor Cyan
}
function Ok([string]$msg){ Write-Host "✅ $msg" -ForegroundColor Green }
function Warn([string]$msg){ Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Fail([string]$msg){ throw $msg }

function Find-CmdPath([string]$name){
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  $p = (& where.exe $name 2>$null | Select-Object -First 1)
  if([string]::IsNullOrWhiteSpace($p)){ return $null }
  return $p.Trim()
}

# Correct cmd.exe quoting for paths with spaces:
# cmd.exe /d /s /c ""C:\Program Files\nodejs\npm.cmd" ci"
function Run-CmdLine([string]$exePath, [string]$tail){
  if(!(Test-Path $exePath)){ Fail "Missing exe: $exePath" }
  if([string]::IsNullOrWhiteSpace($tail)){ Fail "Empty command tail for: $exePath" }

  $cmdString = '""' + $exePath + '" ' + $tail + '"'

  Write-Host ""
  Write-Host "▶ cmd.exe /d /s /c $cmdString" -ForegroundColor DarkCyan

  & cmd.exe /d /s /c $cmdString
  if($LASTEXITCODE -ne 0){
    Fail "Command failed (exit $LASTEXITCODE): $exePath $tail"
  }
}

try {
  $root = (Get-Location).Path
  Title "VERCEL PROD DEPLOY (FINAL)"
  Write-Host "📍 Project root: $root" -ForegroundColor Gray

  if(!(Test-Path (Join-Path $root "package.json"))){
    Fail "package.json not found. You are not in the project root."
  }

  $npmCmd = Find-CmdPath "npm.cmd"
  if(-not $npmCmd){ $npmCmd = "C:\Program Files\nodejs\npm.cmd" }
  if(!(Test-Path $npmCmd)){ Fail "npm.cmd not found. Expected: $npmCmd" }
  Ok "Using npm: $npmCmd"

  $vercelCmd = Find-CmdPath "vercel.cmd"
  if(-not $vercelCmd){
    Title "Installing Vercel CLI (global)"
    Run-CmdLine $npmCmd "i -g vercel"
    $vercelCmd = Find-CmdPath "vercel.cmd"
  }
  if(-not $vercelCmd -or !(Test-Path $vercelCmd)){ Fail "vercel.cmd not found after install." }
  Ok "Using vercel: $vercelCmd"

  Title "Clean cache"
  if(Test-Path ".next"){ Remove-Item -Recurse -Force ".next" -ErrorAction SilentlyContinue; Ok ".next removed" }
  else { Ok ".next not present" }

  Title "Install dependencies"
  try {
    Run-CmdLine $npmCmd "ci"
    Ok "npm ci OK"
  } catch {
    Warn "npm ci failed — falling back to npm install"
    Run-CmdLine $npmCmd "install"
    Ok "npm install OK"
  }

  Title "Local build (fail-fast)"
  Run-CmdLine $npmCmd "run build"
  Ok "Build OK"

  Title "Vercel auth"
  try {
    Run-CmdLine $vercelCmd "whoami"
    Ok "Vercel auth OK"
  } catch {
    Warn "Not logged in — starting vercel login"
    Run-CmdLine $vercelCmd "login"
  }

  Title "Link project"
  try {
    Run-CmdLine $vercelCmd "link --yes"
    Ok "Linked (auto)"
  } catch {
    Warn "Auto link failed — running interactive link"
    Run-CmdLine $vercelCmd "link"
    Ok "Linked (interactive)"
  }

  Title "Deploying to PRODUCTION"
  Run-CmdLine $vercelCmd "deploy --prod"

  Title "DONE"
  Write-Host "✅ If Vercel printed a URL above, open it and test Generate." -ForegroundColor Green
}
catch {
  Write-Host ""
  Write-Host "❌ DEPLOY FAILED" -ForegroundColor Red
  Write-Host $_ -ForegroundColor Red
}
finally {
  Pause-Shell
}
