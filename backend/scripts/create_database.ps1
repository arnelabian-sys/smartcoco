# Creates the SmartCoco role + database with psql.
#
#   cd backend
#   .\scripts\create_database.ps1
#
# psql will ask for the password of the `postgres` superuser (the one you chose
# when PostgreSQL was installed).

$ErrorActionPreference = "Stop"

$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psql)) {
    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "psql.exe was not found. Add PostgreSQL's bin folder to PATH or edit this script."
    }
    $psql = $cmd.Source
}

$sql = Join-Path $PSScriptRoot "create_database.sql"
Write-Host "Running $sql as postgres..." -ForegroundColor Cyan
& $psql -h localhost -p 5432 -U postgres -d postgres -v ON_ERROR_STOP=0 -f $sql

Write-Host ""
Write-Host "Done. Check pgAdmin: Databases -> smartcoco (owner: smartcoco)." -ForegroundColor Green
Write-Host "Then start the API:  .\run.ps1" -ForegroundColor Green
