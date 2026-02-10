param([switch]$Prod)
$ErrorActionPreference="Stop"

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
function Die([string]$msg){ throw $msg }

function Require-Cmd([string]$name){
  $c=Get-Command $name -ErrorAction SilentlyContinue
  if(-not $c){ Die "Command not found in PATH: $name" }
  return $c.Source
}

function Run([string]$exe,[string[]]$args){
  $argLine = ($args | ForEach-Object { if($_ -match "\s"){ "`"$_`"" } else { $_ } }) -join " "
  Write-Host ""
  Write-Host "▶ $exe $argLine" -ForegroundColor DarkCyan
  & $exe @args
  $code=$LASTEXITCODE
  if($code -ne 0){ Die "$exe failed (exit $code)" }
}

try{
  $ProjectRoot=(Get-Location).Path
  Title "Vercel Deploy (NPM ARGUMENTS FIXED)"
  Write-Host "📍 Project root: $ProjectRoot" -ForegroundColor Gray

  if(!(Test-Path (Join-Path $ProjectRoot "package.json"))){
    Die "package.json not found. cd into your project root first."
  }

  $node=Require-Cmd "node"
  $npm =Require-Cmd "npm"

  # IMPORTANT: use -v (more reliable than --version with weird shells)
  Run $node @("-v")
  Run $npm  @("-v")

  $vercelCmd=Get-Command vercel -ErrorAction SilentlyContinue
  if(-not $vercelCmd){
    Title "Installing Vercel CLI"
    Run $npm @("i","-g","vercel")
    $vercel=Require-Cmd "vercel"
    Ok "Vercel CLI installed"
  } else {
    $vercel=$vercelCmd.Source
    Ok "Vercel CLI found"
  }

  Title "Cleaning cache"
  $nextDir=Join-Path $ProjectRoot ".next"
  if(Test-Path $nextDir){
    Remove-Item -Recurse -Force $nextDir -ErrorAction SilentlyContinue
    Ok ".next removed"
  } else { Ok ".next not present" }

  Title "Installing dependencies"
  try{
    Run $npm @("ci")
    Ok "npm ci OK"
  } catch {
    Warn "npm ci failed. Falling back to npm install..."
    Run $npm @("install")
    Ok "npm install OK"
  }

  Title "Local build"
  Run $npm @("run","build")
  Ok "Build OK"

  Title "Vercel auth"
  try{
    & $vercel "whoami" | Out-Host
    if($LASTEXITCODE -ne 0){ throw "whoami failed" }
    Ok "Vercel auth OK"
  } catch {
    Warn "Not logged in — starting login"
    Run $vercel @("login")
  }

  Title "Linking project"
  try{
    Run $vercel @("link","--yes")
    Ok "Linked (auto)"
  } catch {
    Warn "Auto link failed — running interactive link"
    Run $vercel @("link")
    Ok "Linked (interactive)"
  }

  Title "Deploying"
  if($Prod){
    Run $vercel @("deploy","--prod")
    Ok "Production deploy complete"
  } else {
    Run $vercel @("deploy")
    Ok "Preview deploy complete"
  }

  Title "DONE"
  Write-Host "If Vercel printed a URL above, open it and test Generate." -ForegroundColor Green
}
catch{
  Write-Host ""
  Write-Host "❌ SCRIPT FAILED" -ForegroundColor Red
  Write-Host $_ -ForegroundColor Red
}
finally{
  Pause-Shell
}

