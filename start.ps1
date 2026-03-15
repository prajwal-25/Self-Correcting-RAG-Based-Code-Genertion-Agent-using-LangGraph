# Start Coder Agent (Windows PowerShell)
# Usage: .\start.ps1
# Requirements:
#   - Python 3.11+ with requirements.txt installed
#   - MISTRAL_API_KEY in .env or environment
#   - Flutter SDK installed

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load .env if present
$envFile = Join-Path $ScriptDir ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#][^=]*)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
        }
    }
    Write-Host "✅ Loaded .env" -ForegroundColor Green
}

# Start FastAPI backend in a new window
Write-Host "🐍 Starting FastAPI backend on http://localhost:8000 ..." -ForegroundColor Cyan
$BackendJob = Start-Job -ScriptBlock {
    Set-Location $using:ScriptDir
    uvicorn api:app --reload --port 8000 --host 0.0.0.0
}

Write-Host "⏳ Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 4

# Start Flutter web
Write-Host "🦋 Starting Flutter web on http://localhost:5200 ..." -ForegroundColor Magenta
Set-Location (Join-Path $ScriptDir "coder_app")

# Delay then automatically launch the browser so the user doesn't have to copy-paste
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 12
    Start-Process "http://localhost:5200"
}

flutter run -d web-server --web-port 5200 --web-hostname localhost

# Cleanup
Stop-Job $BackendJob
Remove-Job $BackendJob
