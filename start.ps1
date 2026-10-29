# Starts the SmartCoco full stack for a local demo:
#   1. FastAPI backend  -> http://localhost:8000/docs
#   2. Flutter web build -> http://localhost:5000
#
# Usage (from anywhere):
#   .\start.ps1
#
# Press Ctrl+C does NOT stop the servers (they run in the background).
# Stop them with:
#   Get-NetTCPConnection -LocalPort 8000,5000 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$python = Join-Path $root "backend\.venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = (Get-Command python -ErrorAction SilentlyContinue).Source
}
if (-not $python) {
    throw "Python was not found. Create the venv first: cd backend; python -m venv .venv; .\.venv\Scripts\pip install -r requirements.txt"
}

function Test-Port([int]$port) {
    return [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

# --- 1. API ---------------------------------------------------------------
if (Test-Port 8000) {
    Write-Host "API already running on http://localhost:8000" -ForegroundColor Yellow
}
else {
    Write-Host "Starting API..." -ForegroundColor Cyan
    Start-Process -FilePath $python `
        -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000" `
        -WorkingDirectory (Join-Path $root "backend") `
        -WindowStyle Hidden
}

$ready = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    try {
        $null = Invoke-RestMethod "http://127.0.0.1:8000/api/v1/health" -TimeoutSec 2
        $ready = $true
        break
    }
    catch { }
}
if (-not $ready) {
    throw "The API did not start. Check that PostgreSQL 18 is running and that backend\.env is correct."
}
Write-Host "API ready:  http://localhost:8000/docs" -ForegroundColor Green

# --- 2. Web build ---------------------------------------------------------
$web = Join-Path $root "build\web"
if (-not (Test-Path $web)) {
    throw "build\web was not found. Run: flutter build web --release"
}

if (Test-Port 5000) {
    Write-Host "Port 5000 is already serving something." -ForegroundColor Yellow
}
else {
    Write-Host "Starting web server..." -ForegroundColor Cyan
    Start-Process -FilePath $python `
        -ArgumentList "-m", "http.server", "5000", "--directory", $web `
        -WorkingDirectory $root `
        -WindowStyle Hidden
}
Write-Host "App ready:  http://localhost:5000" -ForegroundColor Green

Start-Process "http://localhost:5000"

Write-Host ""
Write-Host "Admin login: http://localhost:5000/#/admin/login" -ForegroundColor Cyan
Write-Host "Hard refresh after every rebuild: Ctrl+Shift+R" -ForegroundColor Cyan
