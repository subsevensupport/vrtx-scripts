# =====================================================================
# Vortex Systems - Installer
# Downloads and runs setup from GitHub
# =====================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Vortex Systems - Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$targetDir = "C:\scripts"
$repoUrl = "https://raw.githubusercontent.com/subsevensupport/vrtx-scripts/main"

# Create directory
if (-not (Test-Path $targetDir)) {
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
}

# Download setup script
Write-Host "Downloading setup script..." -ForegroundColor Cyan
try {
    $url = "$repoUrl/Setup-Everything.ps1"
    $destination = Join-Path $targetDir "Setup-Everything.ps1"
    Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
    Write-Host "[OK] Downloaded" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Download failed: $($_.Exception.Message)" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "Starting setup..." -ForegroundColor Cyan
Write-Host ""

# Run the script content directly in current session (no new process, no execution policy issue)
$scriptContent = Get-Content "$targetDir\Setup-Everything.ps1" -Raw
Invoke-Expression $scriptContent
