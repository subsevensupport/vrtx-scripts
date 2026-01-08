# =====================================================================
# Vortex User Setup - Auto Installer
# Downloads and installs from GitHub
# =====================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "     Vortex User Setup - Installing from GitHub..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$targetDir = "C:\scripts"
$repoUrl = "https://raw.githubusercontent.com/subsevensupport/vrtx-scripts/main"

# Files to download
$files = @(
    "User-DriveMapper.ps1",
    "Deploy-Printers-Users.ps1",
    "2-User-Setup.bat",
    "README.txt"
)

# Create directory
Write-Host "Creating directory: $targetDir" -ForegroundColor Gray
if (-not (Test-Path $targetDir)) {
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
}

# Download files
Write-Host ""
Write-Host "Downloading files..." -ForegroundColor Cyan
$downloadCount = 0

foreach ($file in $files) {
    try {
        Write-Host "  [" -NoNewline
        Write-Host "$($downloadCount + 1)/$($files.Count)" -NoNewline -ForegroundColor Yellow
        Write-Host "] $file... " -NoNewline
        
        $url = "$repoUrl/$file"
        $destination = Join-Path $targetDir $file
        
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
        
        Write-Host "OK" -ForegroundColor Green
        $downloadCount++
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
if ($downloadCount -eq $files.Count) {
    Write-Host "All files downloaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Files installed to: $targetDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Starting setup..." -ForegroundColor Cyan
    Write-Host ""
    
    # Run User Setup
    Set-Location $targetDir
    & "$targetDir\2-User-Setup.bat"
} else {
    Write-Host "Download incomplete. $downloadCount of $($files.Count) files downloaded." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Write-Host ""
    pause
}
