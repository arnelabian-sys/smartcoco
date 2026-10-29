# SmartCoco API - one-command local start (Windows PowerShell)
#
#   .\run.ps1
#
# Creates the virtual environment on first run, installs the dependencies,
# copies .env.example to .env when missing, then starts uvicorn with reload.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Find-Python {
    $candidate = Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"
    if (Test-Path $candidate) { return $candidate }

    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -notlike "*WindowsApps*") { return $cmd.Source }

    $cmd = Get-Command py -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Python 3.12 was not found. Install it from python.org and run this script again."
}

$python = Find-Python

if (-not (Test-Path ".venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Cyan
    & $python -m venv .venv
}

$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
& $venvPython -m pip install --quiet --upgrade pip
& $venvPython -m pip install --quiet -r requirements.txt

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env - change SMARTCOCO_SECRET_KEY before deploying." -ForegroundColor Yellow
}

Write-Host "Starting SmartCoco API on http://localhost:8000 (docs: /docs)" -ForegroundColor Green
& $venvPython -m uvicorn app.main:app --reload --port 8000
