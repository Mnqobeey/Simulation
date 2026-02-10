$ErrorActionPreference = "Stop"
Write-Host "Deploying to Vercel..." -ForegroundColor Green
vercel --prod
